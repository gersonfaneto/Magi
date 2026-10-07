#!/usr/bin/env janet
# Regression tests for bin/magi.d/idle.janet.
#
# The command is almost all side effects, so the real bin/magi runs against
# stubbed systemctl/systemd-run/notify-send. The systemctl stub keeps one marker
# file per unit, so is-active, start, stop and show agree across calls; the
# systemd-run stub records the timer it would have armed.

(use judge)
(use sh)
(import magi)
(import spork/path)

(def- bin (magi/path :home "bin/magi"))
(def- stubs (magi/path :test "magi/idle.d/bin"))
(def- work
  (let [dir (path/join (magi/path :runtime "test.d") (string "idle-" (os/getpid)))]
    (os/mkdir (magi/path :runtime))
    (os/mkdir (path/join (magi/path :runtime "test.d")))
    (os/mkdir dir)
    dir))
(def- state (path/join work "state"))
(def- log (path/join work "log"))
(os/mkdir state)

(defn- mark [unit] (spit (path/join state unit) ""))
(defn- marked? [unit] (truthy? (os/stat (path/join state unit) :mode)))

(defn- reset! []
  (each name (os/dir state) (os/rm (path/join state name)))
  (spit log ""))

(defn- magi-idle [& args]
  (def out @"")
  (def code
    (magi/with-envvars ["XDG_BIN_HOME" stubs
                       "MAGI_TEST_LOG" log
                       "MAGI_TEST_IDLE_STATE" state]
      (first (run ,bin idle ,;args > ,out > [stderr out]))))
  [code (string/trim out)])

(defn- logged [] (string/trim (slurp log)))

(defn- found? [text haystack]
  (truthy? (string/find text haystack)))

(defn- says? [result text]
  (found? text (last result)))


(deftest idle/status
  (reset!)
  (test (magi-idle "status") [0 "Idle timers: off\nSleep inhibitor: off"])
  # Bare idle is the same query.
  (test (magi-idle) [0 "Idle timers: off\nSleep inhibitor: off"]))


(deftest idle/off
  (reset!)
  (mark "hypridle")
  (test (magi-idle "off") [0 ""])
  (test (found? "systemctl --user stop hypridle" (logged)) true)
  (test (found? "notify-send" (logged)) true)
  (test (marked? "hypridle") false)
  (test (last (magi-idle "status")) "Idle timers: off\nSleep inhibitor: off"))


(deftest idle/on
  (reset!)
  (test (magi-idle "on") [0 ""])
  (test (found? "systemctl --user start hypridle" (logged)) true)
  (test (last (magi-idle "status")) "Idle timers: on\nSleep inhibitor: off"))


(deftest idle/toggle
  (reset!)
  # Off -> on.
  (test (first (magi-idle "toggle")) 0)
  (test (marked? "hypridle") true)
  (test (last (magi-idle "status")) "Idle timers: on\nSleep inhibitor: off")
  # ...and back.
  (test (first (magi-idle "toggle")) 0)
  (test (marked? "hypridle") false)
  (test (last (magi-idle "status")) "Idle timers: off\nSleep inhibitor: off"))


(deftest idle/sleep
  (reset!)
  (test (first (magi-idle "off" "--sleep")) 0)
  (def calls (logged))
  (test (found? "--unit=magi-idle-inhibit" calls) true)
  (test (found? "systemd-inhibit --what=sleep --who=magi idle --why=magi idle off --mode=block sleep infinity"
                calls)
        true)
  (test (marked? "magi-idle-inhibit") true)
  (test (last (magi-idle "status")) "Idle timers: off\nSleep inhibitor: on")
  # `on` drops it again.
  (test (first (magi-idle "on")) 0)
  (test (found? "systemctl --user stop magi-idle-inhibit" (logged)) true)
  (test (marked? "magi-idle-inhibit") false)
  (test (last (magi-idle "status")) "Idle timers: on\nSleep inhibitor: off"))


(deftest idle/for
  (reset!)
  (test (first (magi-idle "off" "--for" "2h")) 0)
  (def calls (logged))
  (test (found? "--on-active=2h" calls) true)
  (test (found? "--unit=magi-idle-restore" calls) true)
  # Armed before hypridle is stopped, so a failure can't leave the screen on
  # forever with nothing to bring the timers back.
  (test (< (string/find "--on-active=2h" calls)
           (string/find "stop hypridle" calls))
        true)
  (test (last (magi-idle "status")) "Idle timers: off\nSleep inhibitor: off\nRestore in: 2h 0m")
  # Whole hours and minutes; seconds only once there's nothing bigger left.
  (spit (path/join state "magi-idle-restore.timer.left") "3661")
  (test (last (magi-idle "status"))
        "Idle timers: off\nSleep inhibitor: off\nRestore in: 1h 1m"))


(deftest idle/sleep-for
  (reset!)
  (test (first (magi-idle "off" "--sleep" "--for" "90min")) 0)
  # The inhibitor expires on the same clock as the restore timer.
  (test (found? "--property=RuntimeMaxSec=90min" (logged)) true))


(deftest idle/on-cancels-restore
  (reset!)
  (magi-idle "off" "--for" "1h")
  (test (found? "Restore in: 1h 0m" (last (magi-idle "status"))) true)
  (magi-idle "on")
  (test (found? "systemctl --user stop magi-idle-restore.timer" (logged)) true)
  (test (found? "Restore in:" (last (magi-idle "status"))) false))


(deftest idle/for-fails-before-stopping
  (reset!)
  (mark "hypridle")
  (mark "refuse")
  # The timer is refused, so nothing gets stopped.
  (test (first (magi-idle "off" "--for" "bogus")) 127)
  (test (found? "stop hypridle" (logged)) false)
  (test (last (magi-idle "status")) "Idle timers: on\nSleep inhibitor: off"))


(deftest idle/usage
  (reset!)
  (def [code out] (magi-idle "bogus"))
  (test code 127)
  (test (found? "Usage:" out) true)
  (test (found? "idle off" out) true))
