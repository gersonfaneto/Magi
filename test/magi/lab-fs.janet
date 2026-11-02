#!/usr/bin/env janet
# Regression tests for bin/lab.d/fs.zsh, against stubbed sshfs,
# mountpoint, unmount helpers, and the login shell.

(use judge)
(use sh)
(import magi)
(import spork/path)

(def- script (magi/path :home "bin/lab.d/fs.zsh"))
(def- zsh (string/trim ($<_ sh -c "command -v zsh")))
(def- stubs (magi/path :test "magi/lab-fs.d/bin"))
(def- base
  (let [dir (magi/path :runtime "test.d")]
    (os/mkdir (magi/path :runtime))
    (os/mkdir dir)
    dir))
(def- log (path/join base (string "lab-fs-" (os/getpid) ".log")))
(var cases 0)

(defn- tmpdir []
  (++ cases)
  (def dir (path/join base (string "lab-fs-case-" cases)))
  (os/mkdir dir)
  dir)

(defn- run-fs [opts & args]
  (def tmp (tmpdir))
  (when-let [sub (get opts :subdir)]
    (os/execute @["mkdir" "-p" (path/join tmp "mnt" sub)] :p))
  (spit log "")
  (def out @"")
  (def code
    (magi/with-envvars ["PATH" (string stubs ":" (os/getenv "PATH"))
                        "XDG_BIN_HOME" stubs
                        "FS_TEST_LOG" log
                        "FS_TEST_TMP" tmp
                        "TMPDIR" tmp
                        "SSHFS_EXIT" (string (get opts :sshfs 0))
                        "MOUNTPOINT_EXIT" (string (get opts :mountpoint 0))
                        "FUSERMOUNT3_U_EXIT" (string (get opts :fuser3u 0))
                        "FUSERMOUNT3_UZ_EXIT" (string (get opts :fuser3uz 0))
                        "FUSERMOUNT_EXIT" (string (get opts :fuser 1))
                        "UMOUNT_EXIT" (string (get opts :umount 1))
                        "ZSH_EXIT" (string (get opts :zsh 0))]
      (first (run ,zsh ,script ,;args > ,out > [stderr out]))))
  [code (string out) tmp])

(defn- logged []
  (string (slurp log)))

(defn- contains? [haystack needle]
  (not= nil (string/find needle haystack)))


(deftest fs/usage
  (def [code out] (run-fs {}))
  (test code 64)
  (test (contains? out "usage: fs.zsh") true)
  (test (logged) ""))


(deftest fs/defaults-remote-to-root
  (def [code out tmp] (run-fs {} "example.org"))
  (test code 0)
  (test (contains? out (string "Mounting example.org:/ at " tmp "/mnt...")) true)
  (test (contains? (logged) (string "mktemp -d " tmp "/sshfs-example.org.XXXXXX")) true)
  (test (contains? (logged)
                   (string "sshfs example.org:/ " tmp "/mnt -o "
                           "reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,idmap=user,follow_symlinks"))
        true)
  (test (contains? (logged) (string "mountpoint -q " tmp "/mnt")) true)
  (test (contains? (logged)
                   (string "zsh -l pwd=" tmp "/mnt mount=" tmp "/mnt remote=example.org:/"))
        true)
  (test (contains? (logged) (string "fusermount3 -u " tmp "/mnt")) true)
  (test (contains? out (string "Unmounting " tmp "/mnt...")) true)
  (test (os/stat (path/join tmp "mnt") :mode) nil))


(deftest fs/remote-path-and-subpath
  (def [code out tmp] (run-fs {:subdir "apps"} "root@example.org:/mnt/apps" "/apps"))
  (test code 0)
  (test (contains? (logged) (string "mktemp -d " tmp "/sshfs-example.org.XXXXXX")) true)
  (test (contains? (logged)
                   (string "sshfs root@example.org:/mnt/apps " tmp "/mnt -o "))
        true)
  (test (contains? (logged)
                   (string "zsh -l pwd=" tmp "/mnt/apps mount=" tmp "/mnt remote=root@example.org:/mnt/apps"))
        true)
  (test (contains? out (string "Entering shell in " tmp "/mnt/apps")) true)
  (test (contains? (logged) (string "fusermount3 -u " tmp "/mnt")) true))


(deftest fs/missing-subpath
  (def [code out tmp] (run-fs {} "example.org" "nope"))
  (test code 1)
  (test (contains? out "no such directory on remote: nope") true)
  (test (contains? (logged) (string "fusermount3 -u " tmp "/mnt")) true)
  (test (os/stat (path/join tmp "mnt") :mode) nil))


(deftest fs/mount-failure
  (def [code out tmp] (run-fs {:sshfs 1} "example.org"))
  (test code 1)
  (test (contains? out "sshfs failed to mount example.org:/") true)
  (test (contains? (logged) "fusermount3") false)
  (test (os/stat (path/join tmp "mnt") :mode) nil))


(deftest fs/mountpoint-failure
  (def [code out tmp] (run-fs {:mountpoint 1} "example.org"))
  (test code 1)
  (test (contains? out "is not a mountpoint after sshfs returned success") true)
  (test (contains? (logged) (string "fusermount3 -u " tmp "/mnt")) true)
  (test (os/stat (path/join tmp "mnt") :mode) nil))


(deftest fs/busy-unmount-falls-back-to-lazy
  (def [code out tmp] (run-fs {:fuser3u 1 :fuser 1 :umount 1} "example.org"))
  (test code 0)
  (test (contains? out (string "WARNING: " tmp "/mnt is busy, detaching lazily")) true)
  (def lines (string/split "\n" (logged)))
  (def first-unmount (index-of (string "fusermount3 -u " tmp "/mnt") lines))
  (def lazy (index-of (string "fusermount3 -uz " tmp "/mnt") lines))
  (test (not= nil first-unmount) true)
  (test (not= nil lazy) true)
  (test (> lazy first-unmount) true)
  (test (os/stat (path/join tmp "mnt") :mode) nil))


(deftest fs/propagates-shell-status
  (def [code out tmp] (run-fs {:zsh 7} "example.org"))
  (test code 7)
  (test (contains? (logged) (string "fusermount3 -u " tmp "/mnt")) true)
  (test (os/stat (path/join tmp "mnt") :mode) nil))


(deftest fs/sigint-unmounts
  (def tmp (tmpdir))
  (spit log "")
  (def [code out]
    (magi/with-envvars ["PATH" (string stubs ":" (os/getenv "PATH"))
                        "XDG_BIN_HOME" stubs
                        "FS_TEST_LOG" log
                        "FS_TEST_TMP" tmp
                        "TMPDIR" tmp
                        "ZSH_SLEEP" "1"]
      (with [proc (os/spawn @[zsh script "example.org"] :p
                            {:out :pipe :err :pipe})]
        (os/sleep 0.5)
        (os/proc-kill proc false :int)
        (def [out err code]
          (ev/gather (ev/read (proc :out) :all)
                     (ev/read (proc :err) :all)
                     (os/proc-wait proc)))
        [code (string (or out "") (or err ""))])))
  (test code 130)
  (test (contains? out (string "Unmounting " tmp "/mnt...")) true)
  (test (contains? (logged) (string "fusermount3 -u " tmp "/mnt")) true)
  (test (os/stat (path/join tmp "mnt") :mode) nil))
