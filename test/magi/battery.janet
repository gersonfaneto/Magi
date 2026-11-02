#!/usr/bin/env janet
# Regression tests for bin/magi.d/battery.janet and lib/magi/battery.janet.
#
# The policy is pure, so most of this pins transitions and event order with
# synthetic samples. The command half runs the real bin/magi against stubbed
# UPower/system tools, which is where the header, option parsing and the
# side-effect wiring live.

(use judge)
(use sh)
(import magi)
(import magi/battery)
(import spork/json)
(import spork/path)

(def- bin (magi/path :home "bin/magi"))
(def- fixtures (magi/path :test "magi/battery.d"))
(def- stubs (path/join fixtures "bin"))
(def- info (path/join fixtures "laptop"))
(def- log
  (let [dir (magi/path :runtime "test.d")]
    (os/mkdir (magi/path :runtime))
    (os/mkdir dir)
    (path/join dir (string "battery-" (os/getpid) ".log"))))

(def- cfg
  {:low 20
   :critical 10
   :action 5
   :grace 60
   :repeat 300
   :cooldown 300
   :guardSleep true
   :notify true
   :sound false})

(defn- sample [pct &named state time]
  (def state (or state 2))
  {:present true
   :pct pct
   :state state
   :charging (or (= state 1) (= state 4) (= state 5))
   :full (= state 4)
   :discharging (or (= state 2) (= state 6))
   :time-to-empty (or time 0)
   :time-to-full 0
   :rate 0})

(defn- types [result]
  (map |(get $0 :type) (get result :events)))

(defn- magi-battery [pct state time & args]
  (spit log "")
  (def out @"")
  (def code
    (magi/with-envvars ["XDG_DATA_HOME" info
                       "XDG_BIN_HOME" stubs
                       "MAGI_BATTERY_PATH" stubs
                       "MAGI_TEST_LOG" log
                       "BATTERY_PRESENT" "true"
                       "BATTERY_PCT" (string pct)
                       "BATTERY_STATE" (string state)
                       "BATTERY_TIME" (string time)]
      (first (run ,bin battery ,;args > ,out > [stderr out]))))
  [code (string/trim out)])

(defn- logged []
  (var text "")
  (repeat 20
    (set text (string/trim (slurp log)))
    (unless (empty? text) (break))
    (os/sleep 0.05))
  text)


(deftest battery/thresholds
  (test (map |(battery/threshold-level $0 cfg) [21 20 19 10 9 5 4])
        @[:none :low :low :critical :critical :action :action])
  (test (map battery/rank [:none :low :critical :action]) @[0 1 2 3])
  (test (battery/duration 0) nil)
  (test (battery/duration 59) "0m")
  (test (battery/duration 3600) "1h 0m")
  (test (battery/duration 3900) "1h 5m"))


(deftest battery/low-warning
  (def result (battery/decide {} (sample 19 :time 3600) 100 cfg))
  (test (types result) @[:notify])
  (test (get (first (get result :events)) :level) :low)
  (test (get (first (get result :events)) :body)
        "19% (1h 0m remaining). Plug in soon.")
  # The same sample again is not a second warning.
  (test (types (battery/decide (get result :state) (sample 19) 120 cfg)) @[]))


(deftest battery/skips-straight-to-critical
  (def result (battery/decide {} (sample 9 :time 1800) 100 cfg))
  (test (types result) @[:notify :inhibit])
  (test (get (first (get result :events)) :level) :critical)
  (test (get (get result :state) :inhibited) true))


(deftest battery/action-grace
  (def low (battery/decide {} (sample 9) 100 cfg))
  (def action (battery/decide (get low :state) (sample 4) 200 cfg))
  (test (types action) @[:notify])
  (test (get (get action :state) :action-since) 200)
  (test (get (get action :state) :inhibited) true)
  # Not yet: the user has `grace` seconds to plug in.
  (test (types (battery/decide (get action :state) (sample 4) 259 cfg)) @[])
  # At the deadline the side-effect layer locks and drops the inhibitor before
  # hibernating; the pure policy only emits the action.
  (def fired (battery/decide (get action :state) (sample 4) 260 cfg))
  (test (types fired) @[:action])
  (test (get (last (get fired :events)) :strategy) "hibernate")
  (test (get (get fired :state) :inhibited) false))


(deftest battery/charging-cancels
  (def low (battery/decide {} (sample 9) 100 cfg))
  (def action (battery/decide (get low :state) (sample 4) 200 cfg))
  (def plugged (battery/decide (get action :state) (sample 4 :state 1) 210 cfg))
  (test (types plugged) @[:release])
  (test (get (get plugged :state) :level) :none)
  (test (get (get plugged :state) :inhibited) false)
  # Unplugging starts a fresh episode, notification and grace included.
  (def again (battery/decide (get plugged :state) (sample 4) 220 cfg))
  (test (types again) @[:notify :inhibit])
  (test (get (get again :state) :action-since) 220))


(deftest battery/critical-repeat
  (def initial (battery/decide {} (sample 9) 100 cfg))
  (test (types (battery/decide (get initial :state) (sample 9) 200 cfg)) @[])
  (def repeat (battery/decide (get initial :state) (sample 9) 400 cfg))
  (test (types repeat) @[:notify])
  (test (get (in (get repeat :events) 0) :title) "Battery still critical"))


(deftest battery/action-cooldown
  (def action (battery/decide {} (sample 4) 100 cfg))
  (def fired (battery/decide (get action :state) (sample 4) 160 cfg))
  (test (types fired) @[:action])
  # A resumed/failed action must not loop immediately.
  (def held (battery/decide (get fired :state) (sample 4) 200 cfg))
  (test (types held) @[:inhibit])
  # Still cooling down: no new action-since until 300s after the last action.
  (test (types (battery/decide (get held :state) (sample 4) 400 cfg)) @[])
  # Once the cooldown passes, a new grace period starts.
  (def again (battery/decide (get held :state) (sample 4) 500 cfg))
  (test (types again) @[])
  (test (get (get again :state) :action-since) 500)
  (test (types (battery/decide (get again :state) (sample 4) 560 cfg))
        @[:action]))


(deftest battery/no-guard
  (def result (battery/decide {} (sample 9) 100 (merge cfg {:guardSleep false})))
  (test (types result) @[:notify]))


(deftest battery/status
  (def [code out] (magi-battery 50 2 3600 "status"))
  (test code 0)
  (test out "50% discharging (1h 0m remaining)"))

(deftest battery/status-json
  (def [code out] (magi-battery 50 2 3600 "status" "--json"))
  (test code 0)
  (def decoded (json/decode out :keywords true))
  (test (get decoded :present) true)
  (test (get decoded :pct) 50)
  (test (get-in decoded [:config :low]) 20))


(deftest battery/watch-once
  (def [code] (magi-battery 9 2 1800 "watch" "--once"))
  (test code 0)
  (test (not= nil (string/find "Battery critical" (logged))) true))


(deftest battery/watch-action
  (def [code] (magi-battery 4 2 600 "watch" "--once"))
  (test code 0)
  (test (not= nil (string/find "loginctl lock-session" (logged))) true)
  (test (not= nil (string/find "systemctl hibernate" (logged))) true))


(deftest battery/usage
  (def [code out] (magi-battery 50 2 0))
  (test code 127)
  (test (not= nil (string/find "Usage:" out)) true))
