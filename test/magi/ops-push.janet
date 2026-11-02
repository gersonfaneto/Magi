#!/usr/bin/env janet
# Regression tests for bin/magi.d/ops.d/push.janet.
#
# ssh and nixos-rebuild are stubs (ops-push.d/bin/*): the first only has to pass
# the probe, the second echoes what it was asked for. What's left to pin is
# which config gets built, since SYSTEM is an ssh destination and rarely a host.

(use judge)
(use sh)
(import magi)

(def- bin (magi/path :home "bin/magi"))
(def- stubs (magi/path :test "magi/ops-push.d/bin"))
(def- workstation (magi/path :test "magi/ops.d/workstation"))
# ramen/soba used to be real hosts; now they're fixture directories, so these
# tests don't lean on whatever happens to live in hosts/.
(def- flake (magi/path :test "magi/ops-push.d/flake"))

(defn- push
  "Run `magi ops push ARGS`, and return [exit-code flake target action]."
  [& args]
  (def out @"")
  (def code
    (magi/with-envvars ["XDG_DATA_HOME" workstation
                       "XDG_BIN_HOME" stubs
                       "DOTFILES_HOME" flake]
      (first (run ,bin ops push ,;args > ,out > [stderr :null]))))
  (def lines (string/split "\n" (string/trim out)))
  (def argv (string/split " " (first lines)))
  (def after |(get argv (inc (or (index-of $0 argv) -2))))
  [code
   (when-let [f (after "--flake")] (last (string/split "#" f)))
   (after "--target-host")
   (first argv)])


(deftest push/system-is-the-host
  (test (push "ramen") [0 "ramen" "ramen" "switch"]))

(deftest push/system-is-not-the-host
  # The reason HOST exists: ssh goes to ramen.lan, but it's ramen that gets built.
  (test (push "ramen.lan" "ramen")
        [0 "ramen" "ramen.lan" "switch"])
  (test (push "10.0.0.2" "ramen" "boot")
        [0 "ramen" "10.0.0.2" "boot"]))

(deftest push/action-is-not-a-host
  # No hosts/boot, so boot is nixos-rebuild's, not a HOST.
  (test (push "soba" "boot") [0 "soba" "soba" "boot"]))

(deftest push/no-such-host
  # Rather than build a config that doesn't exist, or worse, one that does and
  # isn't SYSTEM's.
  (test (first (push "ramen.lan")) 127)
  (test (first (push "ramen.lan" "boot")) 127))
