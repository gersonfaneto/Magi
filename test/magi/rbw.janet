#!/usr/bin/env janet
# Regression tests for config/menu/bin/rbw.janet: the fsel menu rows, entry and
# field picks, and the clipboard/notification hand-off.

(use judge)
(use sh)
(import magi)
(import spork/path)

(def- script (magi/path :config "menu" "bin" "rbw.janet"))
(def- stubs (magi/path :test "magi/rbw.d/bin"))
(def- janet (string/trim ($<_ sh -c "command -v janet")))
(def- base
  (let [dir (magi/path :runtime "test.d")]
    (os/mkdir (magi/path :runtime))
    (os/mkdir dir)
    dir))
(var cases 0)

(defn- run-rbw* [opts & args]
  (++ cases)
  (def dir (path/join base (string "rbw-" (os/getpid) "-" cases)))
  (os/mkdir dir)
  (os/mkdir (path/join dir "magi"))
  (def copied (path/join dir "copied"))
  (def notified (path/join dir "notified"))
  (def log (path/join dir "log"))
  (def input-dir (path/join dir "inputs.d"))
  (def counter (path/join dir "counter"))
  (def added (path/join dir "added"))
  (def edited (path/join dir "edited"))
  (def clipargs (path/join dir "clipargs"))
  (def locked (path/join dir "locked"))
  (os/mkdir input-dir)
  (eachp [i input] (or (opts :inputs) [])
    (spit (path/join input-dir (string (inc i))) input))
  (spit counter "0")
  (when (opts :locked)
    (spit locked "locked"))
  (def code
    (magi/with-envvars ["PATH" (string stubs ":" (os/getenv "PATH"))
                        "XDG_RUNTIME_DIR" dir
                        "XDG_CACHE_HOME" (path/join dir "cache")
                        "RBW_TEST_PICK" (or (opts :pick) "first")
                        "RBW_TEST_INPUT_DIR" input-dir
                        "RBW_TEST_COUNTER" counter
                        "RBW_TEST_COPIED" copied
                        "RBW_TEST_NOTIFY" notified
                        "RBW_TEST_LOG" log
                        "RBW_TEST_ADD_FILE" added
                        "RBW_TEST_EDIT_FILE" edited
                        "RBW_TEST_CLIP_LOG" clipargs
                        "RBW_TEST_LOCKED" locked
                        "RBW_TEST_PICK_LOG" (path/join dir "picked")
                        "EDITOR" (path/join stubs "test-editor")
                        "RBW_TEST_SYNC_FAIL" (if (opts :sync-fail) "1" "")]
      (os/execute @[janet script ;args] :p)))
  (var waited 0)
  (while (and (not (os/stat notified :mode)) (< waited 100))
    (ev/sleep 0.01)
    (++ waited))
  [code copied notified log added edited clipargs])

(defn- run-rbw [pick & args]
  (run-rbw* {:pick pick} ;args))

(defn- copied-text [path]
  (string/trim (slurp path)))

(defn- wait-for-content [path needle]
  (var waited 0)
  (while (and (< waited 200)
              (or (not (os/stat path :mode))
                  (nil? (string/find needle (slurp path)))))
    (ev/sleep 0.01)
    (++ waited))
  (when (os/stat path :mode) (slurp path)))

(deftest picks-the-password-first
  (def [code copied notified log added edited clipargs] (run-rbw "first"))
  (test code 0)
  (test (copied-text copied) "secret-value")
  (test (not= nil (string/find "Copied Password for Example" (slurp notified))) true)
  (test (not= nil (string/find "--sensitive" (slurp clipargs))) true))

(deftest field-skips-the-picker
  (def [code copied notified log added edited clipargs] (run-rbw "first" "--field" "username"))
  (test code 0)
  (test (copied-text copied) "secret-value")
  (test (not= nil (string/find "Copied Username for Example" (slurp notified))) true)
  (test (nil? (string/find "--sensitive" (slurp clipargs))) true))

(deftest custom-fields-use-their-own-name
  (def [code copied notified] (run-rbw "last"))
  (test code 0)
  (test (copied-text copied) "secret-value")
  (test (not= nil (string/find "Copied my-custom-field for Example" (slurp notified))) true))

(deftest creates-an-entry-with-a-generated-password
  (def [code copied notified log added]
    (run-rbw*
      {:inputs ["New Site" "me" "newsite.example" "a note"]}
      "--new"))
  (test code 0)
  (test (copied-text copied) "generated-secret")
  (test (string (slurp added)) "generated-secret\na note\n")
  (test (not= nil (string/find "Created New Site and copied its password" (slurp notified))) true)
  (test (not= nil (string/find "generate 20" (slurp log))) true)
  (test (not= nil (string/find "add New Site me --uri https://newsite.example" (slurp log))) true))

(deftest creates-an-entry-with-a-typed-password
  (def [code copied notified log added]
    (run-rbw*
      {:pick "last"
       :inputs ["Custom" "u" "" "hunter2" "note"]}
      "--new"))
  (test code 0)
  (test (copied-text copied) "hunter2")
  (test (string (slurp added)) "hunter2\nnote\n")
  (test (not= nil (string/find "Created Custom and copied its password" (slurp notified))) true)
  (test (not= nil (string/find "add Custom u" (slurp log))) true))

(deftest edits-a-password-and-keeps-notes
  (def [code copied notified log _ edited]
    (run-rbw* {:pick "action:edit-password"}))
  (test code 0)
  (test (copied-text copied) "generated-secret")
  (test (string (slurp edited)) "generated-secret\nold notes\n")
  (test (not= nil (string/find "Updated Example and copied its password" (slurp notified))) true)
  (test (not= nil (string/find "edit id-1" (slurp log))) true))

(deftest edits-entry-notes
  (def [code copied notified log added edited]
    (run-rbw* {:pick "action:edit-notes" :inputs ["new note\nsecond line"]}))
  (test code 0)
  (test (string (slurp edited)) "secret-value\nnew note\nsecond line\n")
  (test (not= nil (string/find "Updated notes for Example" (slurp notified))) true)
  (test (not= nil (string/find "edit id-1" (slurp log))) true))

(deftest deletes-an-entry
  (def [code _ notified log]
    (run-rbw* {:pick "action:delete"}))
  (test code 0)
  (test (not= nil (string/find "Deleted Example" (slurp notified))) true)
  (test (not= nil (string/find "remove id-1" (slurp log))) true))

(deftest unlocks-before-listing
  (def [code copied notified log]
    (run-rbw* {:locked true}))
  (test code 0)
  (test (copied-text copied) "secret-value")
  (test (not= nil (string/find "Bitwarden vault unlocked" (slurp notified))) true)
  (test (not= nil (string/find "unlock" (slurp log))) true))

(deftest reports-background-sync-failure
  (def [code copied notified log added edited clipargs]
    (run-rbw*
      {:inputs ["Sync Fail" "me" "" "note"]
       :sync-fail true}
      "--new"))
  (test code 0)
  (test (not= nil (string/find "Bitwarden sync failed"
                               (wait-for-content notified "Bitwarden sync failed"))) true))
