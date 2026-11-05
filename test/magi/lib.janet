#!/usr/bin/env janet

(use judge)
(use magi)
(use sh)

(defn- wm-under
  ``What `path :wm` makes of FIXTURE's info.json: the desktop's directory name,
  or "error" if it raised instead of guessing. A subprocess per case, because
  flake/info caches the first info.json it reads for the life of a process.``
  [fixture]
  (with-envvars ["XDG_DATA_HOME" (path :test "magi/lib.d" fixture)]
    ($< janet -e
        "(import magi) (prin (try (magi/path/basename (magi/path :wm)) ([e] \"error\")))")))

(deftest with-envvars
  (test (os/getenv "TEST") nil)
  (with-envvars ["TEST" "123"]
    (test (os/getenv "TEST") "123")
    # A struct drops a nil value, so this used to expand to nothing at all and
    # quietly leave the variable alone.
    (with-envvars ["TEST" nil]
      (test (os/getenv "TEST") nil))
    (test (os/getenv "TEST") "123"))
  (test (os/getenv "TEST") nil))

(deftest path/wm
  # The desktop's name comes from magi.desktop by way of info.json now. It used
  # to come from XDG_CURRENT_DESKTOP, which a tty hasn't got -- so `magi .foo`
  # over there was a janet type error rather than "command not found". A
  # desktop nobody taught me, or none at all, is an error rather than a guess.
  (test (wm-under "hyprland") "hypr")
  (test (wm-under "unknown") "error")
  (test (wm-under "unset") "error"))

# A $PATH entry that isn't executable isn't a command: os/execute raises
# "Permission denied" on it, which used to reach the user as a janet traceback.
# A directory shadows a name just as badly.
(deftest path/find
  (def base (path :runtime "test.d"))
  (os/mkdir (path :runtime))
  (os/mkdir base)
  (def dir (path/join base (string "find-" (os/getpid))))
  (os/mkdir dir)
  (defer (os/execute ["rm" "-rf" dir] :p)
    (def exe (path/join dir "exe"))
    (def plain (path/join dir "plain"))
    (spit exe "#!/bin/sh\n")
    (spit plain "not a program\n")
    (os/execute ["chmod" "+x" exe] :p)

    (test (= (path/find "exe" [dir]) exe) true)
    (test (path/find "plain" [dir]) nil)
    (test (path/find dir) nil)
    (test (path/find (path/join dir "missing") [dir]) nil)
    # The absolute branch has the same rule.
    (test (= (path/find exe) exe) true)
    (test (path/find plain) nil)))

(deftest path/abbrev
  (with-envvars ["HOME" "/home/test"]
    (test (path/abbrev "/home/test") "~")
    (test (path/abbrev "/home/test/foo") "~/foo")
    # A sibling directory is not under HOME.
    (test (path/abbrev "/home/tester/foo") "/home/tester/foo")
    # Nor is a HOME substring that isn't the prefix.
    (test (path/abbrev "/srv/home/test/foo") "/srv/home/test/foo"))
  # Formatting an error message must not raise when there is no HOME.
  (with-envvars ["HOME" nil]
    (test (path/abbrev "/home/test/foo") "/home/test/foo")))
