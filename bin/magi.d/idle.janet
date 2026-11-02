#!/usr/bin/env janet
# Toggle the idle timers (hypridle: lock at 5m, screen off at 6m).
#
# SYNOPSIS:
#   idle [status]
#   idle on
#   idle off [-s|--sleep] [-f|--for DURATION]
#   idle toggle [-s|--sleep] [-f|--for DURATION]
#
# DESCRIPTION:
#   `off` stops hypridle.service, so the session neither locks nor blanks the
#   screen until `on` -- or until DURATION has passed, with `--for`. There's no
#   state file: everything is asked of systemd, so the answer can't drift.
#
#   Hypridle's timeouts are owned by the Idle/Lock surface (config/quickshell),
#   which regenerates its config and restarts the unit whenever they change, so
#   `off` holds until `on`, until DURATION passes, or until that surface applies
#   new values. Its suspend timeout defaults to 0 and logind's IdleAction is
#   "ignore", so this is mostly about the screen; a lid close still suspends,
#   unless `--sleep` holds a logind sleep inhibitor.
#
# OPTIONS:
#   -f DURATION, --for DURATION
#     Turn the timers back on after DURATION, as a systemd time span (30min,
#     2h, 1h30m).
#   -s, --sleep
#     Also hold a logind sleep inhibitor, so a lid close won't suspend.
#
# ARGUMENTS:
#   1 COMMAND
#     status -- Print whether the idle timers are armed, and until when.
#     on     -- Start the timers again, and drop the inhibitor and restore timer.
#     off    -- Stop the timers: the screen won't blank or lock.
#     toggle -- Flip whichever state it is in.

(use magi)
(use sh)
(import magi/sys)

(def- timers "hypridle")
(def- inhibit "magi-idle-inhibit")
(def- restore "magi-idle-restore")
(def- restore-timer (string restore ".timer"))
(def- restore-service (string restore ".service"))

(defn- systemctl [& args]
  (def code (os/execute ["systemctl" "--user" ;args] :p))
  (unless (zero? code)
    (abort "systemctl --user %s: exit %d" (string/join args " ") code)))

(defn- active? [unit]
  (zero? (os/execute ["systemctl" "--user" "is-active" "--quiet" unit] :p)))

(defn- stop-unit! [unit]
  (when (active? unit)
    (systemctl "stop" unit)))

(defn- stop-restore! []
  (stop-unit! restore-timer)
  (stop-unit! restore-service))

(defn- arm-restore! [duration]
  # Armed before anything is stopped, so a typo'd DURATION leaves the timers
  # alone instead of blanking the screen forever.
  (def argv ["systemd-run" "--user" "--quiet" "--collect"
             (string "--on-active=" duration)
             (string "--unit=" restore)
             "systemctl" "--user" "start" timers])
  (unless (zero? (os/execute argv :p))
    (abort "Could not schedule the restore timer for %s" duration)))

(defn- hold-sleep! [duration]
  (def argv @["systemd-run" "--user" "--quiet" "--collect"
              (string "--unit=" inhibit)])
  # Without --for the inhibitor is held until `on`; with it, the unit expires
  # on its own, on the same clock as the restore timer.
  (when duration
    (array/push argv (string "--property=RuntimeMaxSec=" duration)))
  (array/push argv "systemd-inhibit" "--what=sleep" "--who=magi idle"
              "--why=magi idle off" "--mode=block" "sleep" "infinity")
  (unless (zero? (os/execute argv :p))
    (abort "Could not start the sleep inhibitor")))

(defn- off! [&named sleep? duration]
  (stop-restore!)
  # Recreated rather than reused: systemd-run refuses a name that's still taken.
  (stop-unit! inhibit)
  (when duration (arm-restore! duration))
  (systemctl "stop" timers)
  (when sleep? (hold-sleep! duration))
  (sys/toast :info (if duration
                     (string "Idle timers off for " duration)
                     "Idle timers off")
             :details (if sleep?
                        "The screen stays on, and the lid won't suspend."
                        "The screen stays on.")
             :icon "dialog-information"))

(defn- on! []
  (systemctl "start" timers)
  (stop-unit! inhibit)
  (stop-restore!)
  (sys/toast :info "Idle timers on"
             :details "The screen will lock and blank again."
             :icon "dialog-information"))

(defn- span [seconds]
  (def s (math/ceil (max 0 seconds)))
  (cond
    (>= s 3600) (string/format "%dh %dm" (math/floor (/ s 3600))
                               (math/floor (/ (% s 3600) 60)))
    (>= s 60)   (string/format "%dm" (math/floor (/ s 60)))
    (string/format "%ds" s)))

(defn- left []
  # The timer's `next` is a realtime timestamp, even for an --on-active timer,
  # which is what systemd's own list-timers subtracts too.
  (when (active? restore-timer)
    (def out (ignore-errors
              ($<_ systemctl --user list-timers ,restore-timer
                    --output=json --no-pager)))
    (def next (get (first (if out (json/decode out :keywords true) [])) :next))
    (when next
      (span (- (/ next 1e6) (os/time))))))

(defn- status! []
  (echof "Idle timers: %s" (if (active? timers) "on" "off"))
  (echof "Sleep inhibitor: %s" (if (active? inhibit) "on" "off"))
  (when-let [duration (left)]
    (echof "Restore in: %s" duration)))

(defcmd idle [_ cmd & args &opts sleep? [-s --sleep] duration [-f --for duration]]
  (when (and cmd (not (empty? args)))
    (usage))
  (cond
    (nil? cmd)          (status!)
    (= cmd "status")    (status!)
    (= cmd "on")        (on!)
    (= cmd "off")       (off! :sleep? sleep? :duration duration)
    (= cmd "toggle")    (if (active? timers)
                          (off! :sleep? sleep? :duration duration)
                          (on!))
    (usage)))
