#!/usr/bin/env janet
# test/magi/theme.janet --- tests for bin/magi.d/theme.janet

(use judge)
(use magi)
(use sh)
(import spork/path)

(def- dir (path/abspath (path/join (path/dirname (dyn :current-file)) "../..")))
(def- magi-bin (path/join dir "bin/magi"))
(def- stub (path/join (path/dirname (dyn :current-file)) "theme.d/bin"))
(def- devnull (file/open "/dev/null" :w))

(defn- status [& args]
  (os/execute [magi-bin "theme" ;args] :p {:out devnull :err devnull}))

# theme.py's exit code used to be dropped on the floor, so a bad subcommand (or
# a failing render) came back as a successful no-op. The stub stands in for
# python3 and always fails, which is all this needs to know.
(deftest theme/exit-status
  (with-envvars ["XDG_BIN_HOME" stub]
    (test (status "list") 3)
    (test (status "bogus") 3))
  # No subcommand is a usage error, not a successful no-op.
  (test (status) 127))
