#!/usr/bin/env janet

(use judge)
(use sh)
(import magi)

# Ensure zsh helpers are available to these tests.
(def- autoload-magi
  (let [dir (magi/path :lib "zsh")]
    (string "fpath=( " dir " ); autoload -Uz ${fpath[1]}/magi.*(.:t); \"$@\"")))

(defmacro zsh [& args]
  ~(,(first args) zsh -c ,autoload-magi "magi-test"
    ,(string (get args 1)) ,;(slice args 2)))

(deftest magi.requires
  (test (zsh $? magi.requires zsh bash sh) true)
  (test (zsh $? magi.requires zsh bash doesnotexist > [stderr :null]) false))

(deftest magi.do
  (test (zsh $<_ magi.do echo 10) "10")

  # A dry run says what it would do on stderr and does nothing on stdout.
  (magi/with-envvars ["MAGIDRYRUN" "1"]
    (def err @"")
    (test (zsh $< magi.do echo 10 > [stderr err]) "")
    (test (empty? err) false)))
