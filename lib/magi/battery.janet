# lib/magi/battery.janet
#
# UPower-backed battery monitoring and the low-battery policy `magi battery`
# runs as a user service.
#
# The policy is a pure state machine (`decide`) plus a thin side-effect layer
# (`watch`). Keeping the decisions pure is what lets the test suite pin
# threshold crossings, grace periods and inhibitor lifetime without a real
# battery or a running notification server.

(import spork/json)
(import spork/path)
(use ./lib)
(use sh)
(import magi/sys)

(def device-path "/org/freedesktop/UPower/devices/DisplayDevice")
(def device-interface "org.freedesktop.UPower.Device")
(def upower-service "org.freedesktop.UPower")

(def defaults
  {:low 20
   :critical 10
   :action 5
   :grace 60
   :repeat 300
   :cooldown 300
   :interval 20
   :strategy "hibernate"
   :guardSleep true
   :notify true
   :sound true})

(def- *ranks* {:none 0 :low 1 :critical 2 :action 3})

(defn rank
  "The severity of a warning LEVEL, for comparing transitions."
  [level]
  (get *ranks* level 0))

(defn threshold-level
  "The warning level PCT falls under, given policy CFG."
  [pct cfg]
  (cond
    (<= pct (get cfg :action 5)) :action
    (<= pct (get cfg :critical 10)) :critical
    (<= pct (get cfg :low 20)) :low
    :none))

(defn duration
  "Seconds as a short \"1h 5m\" string, or nil when there is no estimate."
  [seconds]
  (when (and seconds (> seconds 0))
    (def h (math/floor (/ seconds 3600)))
    (def m (math/floor (/ (% seconds 3600) 60)))
    (if (> h 0)
      (string h "h " m "m")
      (string m "m"))))

(defn- tool
  ``Resolve an external command.

  magi deliberately replaces `$PATH` with its own login-session cache in
  `dispatch`, so a user unit's `path` isn't visible to child processes. The
  battery unit passes the package bin dirs explicitly in `MAGI_BATTERY_PATH`;
  fall back to magi's own lookup for interactive use.
  ``
  [name]
  (or (when-let [dirs (os/getenv "MAGI_BATTERY_PATH")]
        (path/find name (string/split ":" dirs)))
      (path/find name)
      (path/find name ["/run/current-system/sw/bin" "/run/wrappers/bin"])
      name))

(defn state-label
  "A human label for SAMPLE's charge state."
  [sample]
  (cond
    (get sample :charging) "charging"
    (get sample :full) "full"
    (get sample :discharging) "discharging"
    "unknown"))

(defn status-line
  "One-line human summary of SAMPLE."
  [sample]
  (def pct (math/round (get sample :pct 0)))
  (def left (if (get sample :charging)
              (get sample :time-to-full 0)
              (get sample :time-to-empty 0)))
  (def suffix (if-let [time (duration left)]
                (string " (" time
                        (if (get sample :charging) " to full" " remaining") ")")
                ""))
  (string pct "% " (state-label sample) suffix))

## * UPower

(defn- property
  "Read one UPower.Device property, or nil if busctl can't be asked."
  [name]
  (ignore-errors
    (def out @"")
    (def [code] (run* (tuple (tool "busctl") "--system" "--json=short"
                             "get-property"
                             upower-service device-path device-interface name
                             :> out)))
    (when (zero? code)
      (get (json/decode (string/trim out) :keywords true) :data))))

(defn read-sample
  "A snapshot of UPower's display device, or nil when there is no battery."
  []
  (when (property "IsPresent")
    (def state (or (property "State") 0))
    (def charging (or (= state 1) (= state 4) (= state 5)))
    {:present true
     :pct (or (property "Percentage") 0)
     :state state
     :charging charging
     :full (= state 4)
     :discharging (or (= state 2) (= state 6))
     :time-to-empty (or (property "TimeToEmpty") 0)
     :time-to-full (or (property "TimeToFull") 0)
     :rate (or (property "EnergyRate") 0)
     :warning (property "WarningLevel")}))

## * Policy

(defn- event-notification
  "A notification event for LEVEL, or nil when notifications are off."
  [level sample cfg]
  (when (get cfg :notify true)
    (def pct (math/round (get sample :pct 0)))
    (def time (duration (get sample :time-to-empty 0)))
    (def remaining (if time (string " (" time " remaining)") ""))
    (def sound (if (get cfg :sound true)
                 (if (= level :low) "notify" "notify-critical")))
    (def base {:type :notify
               :level level
               :urgency (if (= level :low) "normal" "critical")
               :icon "battery-caution"
               :sound sound})
    (case level
      :low
      (merge base {:title "Battery low"
                   :body (string pct "%" remaining ". Plug in soon.")})

      :critical
      (merge base {:title "Battery critical"
                   :body (string pct "%" remaining ". Save your work and plug in.")})

      :action
      (merge base {:title "Battery depleted"
                   :body (string pct "% remaining. Hibernating in "
                                     (get cfg :grace 60) "s -- plug in to cancel.")})
      nil)))

(defn- event-repeat
  "A repeat critical notification, or nil when notifications are off."
  [sample cfg]
  (when (get cfg :notify true)
    (def pct (math/round (get sample :pct 0)))
    (def time (duration (get sample :time-to-empty 0)))
    {:type :notify
     :level :critical
     :urgency "critical"
     :icon "battery-caution"
     :sound (if (get cfg :sound true) "notify-critical")
     :title "Battery still critical"
     :body (string "Still at " pct "%"
                   (if time (string " (" time " remaining)"))
                   ". Plug in now.")}))

(defn decide
  ``
  Advance STATE by one SAMPLE at NOW and return {:state NEW :events EVENTS}.

  SAMPLE is from `read-sample`; NOW is in seconds. The events are what the
  side-effect layer should do: :notify, :inhibit, :release and :action.
  ``
  [state sample now cfg]
  (def cfg (merge defaults cfg))
  (def st (merge @{:level :none
                  :action-since nil
                  :last-critical nil
                  :acted-at nil
                  :inhibited false}
                state))
  (def events @[])
  (def discharging (get sample :discharging))
  (def level (if discharging
               (threshold-level (get sample :pct 0) cfg)
               :none))
  (def prev (get st :level :none))

  # Warn once per upward crossing. A jump from 25% to 9% is one critical
  # warning, not a burst of three.
  (when (> (rank level) (rank prev))
    (when-let [event (event-notification level sample cfg)]
      (array/push events event))
    (when (= level :critical)
      (put st :last-critical now)))

  (unless (= level :critical)
    (put st :last-critical nil))
  (unless (= level :action)
    (put st :action-since nil))

  # Repeat critical while the user ignores it, but never more often than
  # :repeat. Action has its own grace notification and doesn't repeat.
  (when (and (= level :critical)
             (= prev :critical)
             (>= (- now (or (get st :last-critical) now)) (get cfg :repeat 300)))
    (when-let [event (event-repeat sample cfg)]
      (array/push events event))
    (put st :last-critical now))

  # Hold a sleep inhibitor through critical and action, so a lid close or an
  # idle hypridle cannot suspend the machine down to zero. Release it as soon
  # as the battery recovers or AC arrives.
  (when (and (get cfg :guardSleep true)
             (or (= level :critical) (= level :action))
             (not (get st :inhibited)))
    (array/push events {:type :inhibit})
    (put st :inhibited true))
  (when (and (get st :inhibited)
             (not (and (get cfg :guardSleep true)
                       (or (= level :critical) (= level :action)))))
    (array/push events {:type :release})
    (put st :inhibited false))

  # At action level, give the user :grace seconds to find a charger, then act.
  # :cooldown keeps a failed or interrupted action from looping immediately.
  (when (= level :action)
    (when (and (nil? (get st :action-since))
               (or (nil? (get st :acted-at))
                   (>= (- now (get st :acted-at)) (get cfg :cooldown 300))))
      (put st :action-since now))
    (when (and (get st :action-since)
               (>= (- now (get st :action-since)) (get cfg :grace 60))
               (or (nil? (get st :acted-at))
                   (>= (- now (get st :acted-at)) (get cfg :cooldown 300))))
      # The inhibitor stays up until the side-effect layer has locked the
      # session; releasing it here would leave a window where idle/lid suspend
      # can race the hibernate.
      (put st :inhibited false)
      (array/push events {:type :action
                          :strategy (get cfg :strategy "hibernate")})
      (put st :action-since nil)
      (put st :acted-at now)))

  # A charge resets the episode, including a hibernate cooldown that would
  # otherwise carry over into the next unplug.
  (when (or (get sample :charging) (= level :none))
    (put st :acted-at nil))

  (put st :level level)
  {:state st :events events})

## * Side effects

(defn- play!
  [name]
  (when-let [file (sys/find-sound name)]
    (unless (string/has-suffix? ".disabled" file)
      (os/spawn [(tool "play") "-q" file] :pd))))

(defn- notify!
  [event]
  (def argv @[(tool "notify-send") "-a" "magi battery"
              "-u" (or (get event :urgency) "normal")])
  (when-let [icon (get event :icon)]
    (array/push argv "-i" icon))
  (array/push argv (or (get event :title) "Battery")
              (or (get event :body) ""))
  (os/spawn argv :pd)
  (when-let [sound (get event :sound)]
    (play! sound)))

(defn- start-inhibitor
  []
  (os/spawn [(tool "systemd-inhibit") "--what=sleep" "--who=magi battery"
             "--why=Battery critically low" "--mode=block"
             (tool "sleep") "infinity"]
            :p))

(defn- stop-inhibitor
  [proc]
  (when proc
    (ignore-errors (os/proc-kill proc true))))

(defn- action-argv
  [strategy]
  (case strategy
    "hybrid-sleep" [(tool "systemctl") "hybrid-sleep"]
    "poweroff" [(tool "systemctl") "poweroff"]
    [(tool "systemctl") "hibernate"]))

(defn- lock-session!
  []
  (ignore-errors (os/execute [(tool "loginctl") "lock-session"] :p))
  (os/sleep 1))

(defn- run-action!
  [strategy runtime]
  # Lock first while the sleep inhibitor is still held, then drop it and let
  # logind hibernate. This exits the session cleanly and closes the race with
  # an idle/lid suspend before the image is written.
  (lock-session!)
  (stop-inhibitor (get runtime :inhibitor))
  (put runtime :inhibitor nil)
  (def code (or (ignore-errors (os/execute (action-argv strategy) :p)) 1))
  (unless (zero? code)
    (notify! {:title "Battery action failed"
              :body "Hibernation failed; powering off instead."
              :urgency "critical"
              :icon "dialog-error"
              :sound "notify-critical"})
    (os/sleep 10)
    (ignore-errors (os/execute [(tool "systemctl") "poweroff"] :p)))
  code)

(defn- handle!
  [event runtime]
  (case (get event :type)
    :notify (notify! event)
    :inhibit (unless (get runtime :inhibitor)
               (put runtime :inhibitor (ignore-errors (start-inhibitor))))
    :release (do
               (stop-inhibitor (get runtime :inhibitor))
               (put runtime :inhibitor nil))
    :action (run-action! (get event :strategy) runtime)))

## * Entry points

(defn config
  "The battery policy from magi's generated info.json, with defaults filled in."
  []
  (def info (ignore-errors
              (json/decode (slurp (path/xdg :data "magi/info.json"))
                           :keywords true)))
  (merge defaults (or (get info :battery) {})))

(defn watch
  "Poll UPower and apply the policy. With ONCE? take a single sample."
  [&named once? interval]
  (def cfg (config))
  (def runtime @{:inhibitor nil})
  (var state @{})
  (defer (stop-inhibitor (get runtime :inhibitor))
    (while true
      (when-let [sample (read-sample)]
        (def result (decide state sample (os/time) cfg))
        (set state (get result :state))
        (each event (get result :events)
          (handle! event runtime)))
      (if once?
        (break)
        (os/sleep (or interval (get cfg :interval 20))))))
  state)

(defn status
  "Print the current battery state. With JSON? emit it as JSON."
  [json?]
  (def cfg (config))
  (def sample (read-sample))
  (if json?
    (echo :json (merge {:present false} (or sample {}) {:config cfg}))
    (if sample
      (echo (status-line sample))
      (echo "No battery present."))))
