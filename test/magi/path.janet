#!/usr/bin/env janet
# test/magi/path.janet --- tests for bin/magi.d/path.janet

(use judge)
(use magi)
(use sh)
(import spork/path)

(def- dir (path/abspath (path/join (path/dirname (dyn :current-file)) "../..")))
(def- magi-bin (path/join dir "bin/magi"))
(def- devnull (file/open "/dev/null" :w))

(defn- status [& args]
  (os/execute [magi-bin "path" ;args] :p {:out devnull}))

(defn- magi-out [& args]
  ($<_ ,magi-bin "path" ,;args))

# `xdg` indexes ARGS from 0: AREA was already taken off the front, so the old
# (get args 1) demanded an argument it had been given and (slice args 2)
# dropped a segment.
(deftest path/xdg
  (with-envvars ["XDG_DATA_HOME" "/tmp/magi-test/data"
                 "XDG_CONFIG_HOME" "/tmp/magi-test/config"]
    (test (magi-out "xdg" "data") "/tmp/magi-test/data")
    (test (magi-out "xdg" "config" "foo" "bar") "/tmp/magi-test/config/foo/bar"))
  # No directory named at all is still an error.
  (test (status "xdg") 127))

(deftest path/exists-flags
  (with-envvars ["DOTFILES_HOME" dir]
    (test (status "-e" "home") 0)
    (test (status "-d" "home") 0)
    (test (status "-f" "home") 1)
    (test (status "-f" "home" "bin" "magi") 0)
    (test (status "-d" "home" "bin" "magi") 1)
    (test (status "-e" "home" "no-such-file") 1)))
