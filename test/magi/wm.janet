#!/usr/bin/env janet
# Regression tests for bin/magi.d/wm.janet and bin/magi.d/wm.d/*.
#
# magi wm is two things in one table: commands compiled into magi, and a fallback
# into config/$WM/bin for everything else. Both halves are pinned here, since
# losing either one is silent -- a keybind that plays nothing, or a script that
# stops being found.

(use judge)
(use sh)
(import magi)

(def- bin (magi/path :home "bin/magi"))
(def- stubs (magi/path :test "magi/wm.d/bin"))
(def- desktops (magi/path :test "magi/lib.d"))
# assets/sounds rides in by symlink, beside a stand-in freedesktop theme, so
# inheritance doesn't hinge on what this machine has installed.
(def- sounds (magi/path :test "magi/lib.d/hyprland/sounds"))
(def- scripts
  (sorted (seq [file :in (os/dir (magi/path :home "bin/magi.d/wm.d"))
                :when (string/has-suffix? ".janet" file)]
            (magi/string/no-suffix ".janet" file))))

(def- log
  (let [dir (magi/path :runtime "test.d")]
    (os/mkdir (magi/path :runtime))
    (os/mkdir dir)
    (magi/path/join dir (string "wm-" (os/getpid) ".play"))))

(defn- magi-wm
  ``Run `magi wm ARGS` on DESKTOP's fixture info.json, with play stubbed out, and
  return [exit-code output].``
  [desktop & args]
  (def out @"")
  (def code
    (magi/with-envvars ["XDG_DATA_HOME" (magi/path/join desktops desktop)
                       # Ahead of $PATH in magi's exec-path; on $PATH alone the
                       # real play would win.
                       "XDG_BIN_HOME" stubs
                       "MAGI_TEST_PLAY_LOG" log]
      (first (run ,bin wm ,;args > ,out > [stderr out]))))
  [code (string/trim out)])

(defn- played
  ``What play was asked, with the sounds dir abbreviated to @. A detached play
  can land after magi exits, so under WAIT? this gives it a moment to.``
  [wait?]
  (var text "")
  (repeat 20
    (set text (string/trim (slurp log)))
    (unless (and wait? (empty? text)) (break))
    (os/sleep 0.05))
  (string/replace-all sounds "@" text))

(defn- play-sound [& args]
  (spit log "")
  (def [code] (magi-wm "hyprland" "play-sound" ;args))
  [code (played (zero? code))])

(defn- says? [[_ out] text] (not= nil (string/find text out)))


(deftest wm/dispatch-table
  # bin/magi.d/wm.d/foo.janet with no import or rule in wm.janet would only
  # exist on disk -- and _magi would still offer it, since it scans wm.d.
  (def out @"")
  (magi/with-envvars ["XDG_DATA_HOME" (magi/path/join desktops "hyprland")]
    ($? ,bin help --dump wm > ,out))
  (test (deep= (sorted (seq [line :in (string/split "\n" (string out))
                             :until (empty? line)]
                         (first (string/split ":" line))))
               scripts)
        true))

(deftest wm/play-sound
  (test (play-sound "-w" "-v" "0.5" "blip") [0 "-q -v 0.5 @/magi/stereo/blip.ogg"])
  # Detached by default: magi is long gone by the time play logs anything.
  # Mine, though freedesktop has one too.
  (test (play-sound "success") [0 "-q @/magi/stereo/success.ogg"])
  # Sheds -parts before falling back to a parent, like a freedesktop sound theme.
  (test (play-sound "success-at-last") [0 "-q @/magi/stereo/success.ogg"])
  (test (play-sound "bell") [0 "-q @/freedesktop/stereo/bell.oga"])
  # Found, but silenced: nothing plays, and that's not an error.
  (test (play-sound "-w" "hush") [0 ""])
  (test (play-sound "no-such-sound") [127 ""])
  (test (says? (magi-wm "hyprland" "play-sound") "Usage:") true)
  # Names, as they'd be passed back in, rather than files.
  (def [code out] (magi-wm "hyprland" "play-sound" "ls"))
  (test code 0)
  (def names (string/split "\n" out))
  (test (truthy? (index-of "blip" names)) true)
  (test (truthy? (index-of "bell" names)) true)
  (test (index-of "hush" names) nil))

(deftest wm/fallback
  # Anything the table doesn't name is a script in config/$WM/bin.
  (def out @"")
  (magi/with-envvars ["XDG_DATA_HOME" (magi/path/join desktops "hyprland")]
    ($? ,bin which wm screencast > ,out))
  # Compared rather than pinned: judge wants a literal on the right.
  (test (= (string/trim out) (magi/path :config "hypr/bin/screencast.zsh")) true)
  # No desktop is a sentence, not a backtrace -- and doesn't take the compiled
  # commands down with it, since they never needed one.
  (test (first (magi-wm "unset" "screencast")) 127)
  (test (first (magi-wm "unset" "play-sound" "-w" "blip")) 0))
