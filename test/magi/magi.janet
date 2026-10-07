#!/usr/bin/env janet

(use judge)
(use sh)
(import magi)
(import spork/path)

(def- dir (slice (path/dirname (dyn :current-file)) 0 -2))

(defmacro* resolve= [type args &opt exp]
  (let [form ~(,(case type :f magi/resolve :d magi/resolve-dir)
                ,(path/join dir (string (first args)))
                ,;(map string (slice args 1)))]
    ~(test ,(if exp form ~(nil? ,form))
           ,(if exp ~[,(path/join dir (first exp)) ,;(slice exp 1)] true))))

(deftest magi/resolve
  (resolve= :f [magi.d sub deeper]               ["magi.d/sub.d/deeper.zsh"])
  (resolve= :f [magi.d sub deeper deep foo]      ["magi.d/sub.d/deeper.d/deep.zsh" "foo"])
  (resolve= :f [does not exist])

  # bin/magi's `.NAME` rule hands over config/$WM/bin, which a tty hasn't got.
  (deftest "A nil in the list is a place not to look, not an error"
    (test (deep= (magi/resolve [nil (path/join dir "magi.d")] "sub" "deeper")
                 (magi/resolve (path/join dir "magi.d") "sub" "deeper"))
          true))

  # A bare name is a $PATH lookup, and a $PATH miss used to leave the base nil,
  # which killed os/stat.
  (deftest "A $PATH miss is nil, not a crash"
    (test (nil? (magi/resolve "definitely-not-a-command-on-path")) true))

  # A flag stops the walk; whatever follows it is the script's.
  (deftest "Forwarding options"
    (resolve= :f [magi.d sub deeper --foo deep]    ["magi.d/sub.d/deeper.zsh" "--foo" "deep"])
    (resolve= :f [magi.d sub deeper deep --foo -b] ["magi.d/sub.d/deeper.d/deep.zsh" "--foo" "-b"])
    # `--` used to un-walk the last step too, handing the script its own name.
    (resolve= :f [magi.d sub deeper -- deep]       ["magi.d/sub.d/deeper.zsh" "--" "deep"])
    (resolve= :d [magi.d sub deeper -- deep]       ["magi.d/sub.d/deeper.d" "--" "deep"])))

(deftest magi/exec-exit-status
  # os/execute hands back the status of the script magi dispatched to, but
  # nothing upstream read a dispatcher's return value, so anything that failed
  # came back as a clean exit 0. Harmless by hand; a lie to a cronjob.
  #
  # Spawned rather than called: the fix exits the process, which would take
  # judge with it.
  # Absolute: magi only recognises a bare path as one when it starts with ./ or
  # /, and anything else is a subcommand name it has never heard of.
  (def magi-bin (path/abspath (path/join dir "../../bin/magi")))
  (defn status [script]
    (os/execute [magi-bin (path/abspath (path/join dir "exec.d" script))] :p))

  (test (status "ok.zsh") 0)
  (test (status "fail.zsh") 42)
  # A rule that names $1 comes out 2-arity, but dispatch hands a rule one
  # argument when nothing follows the command -- `magi exec` used to die of a
  # janet arity error (exit 1) instead of saying which program it wanted (127).
  (test (os/execute [magi-bin "exec"] :p) 127)
  # A signal arrives here as 128+signum, the same way a shell reports it, so it
  # forwards without translation.
  (test (status "sig.zsh") 143))

(deftest magi/nested-rules
  # A :rules fn is how a ruleset refuses to exist somewhere (magi ops, off a
  # workstation), and its file is how it has a header without a :file key.
  (def nested (path/abspath (path/join dir "dispatch.d/nested.janet")))
  (defn nested! [& args]
    (def out @"")
    (def code (first (run janet ,nested ,;args > ,out > [stderr out])))
    [code (string/trim out)])
  (defn says? [[_ out] text] (truthy? (string/find text out)))

  (test (nested! "gated" "one" "a") [0 "one\none\na"])
  # An :eval builder gets the command word too, and hands it on as an argument.
  (test (nested! "gated" "two") [0 "one\ntwo\ntwo"])
  (test (nested! "static" "one") [0 "one\none"])
  # Bare, it's a complaint, its header, and its menu -- without magi's builtins.
  (def bare (nested! "gated"))
  (test (first bare) 1)
  (test (says? bare "nested gated COMMAND") true)
  (test (says? bare "- two  -- Two.") true)
  (test (says? bare "- help") false)
  (test (nested! "help" "gated") [0 "A ruleset only some machines may use.\n\nSYNOPSIS:\n  nested gated COMMAND"])
  # A static ruleset has no file, so its menu is all the help it has.
  (test (nested! "help" "static") [0 "- one  --"])
  (test (nested! "help" "--dump" "gated") [0 "one:A ruleset only some machines may use.\ntwo:Two."])
  (test (first (nested! "static" "nope")) 127)
  # The gate runs whenever the rules are needed, help included.
  (magi/with-envvars ["GATED" "1"]
    (test (nested! "gated" "one") [127 "\e[31m𐄂 gated\e[0m"])
    (test (first (nested! "help" "gated" "one")) 127)))

(deftest magi/defcmd
  # Through import, not use: every script uses magi, so nothing else notices a
  # macro expanding to a bare symbol that only use would've brought into scope.
  (magi/defcmd x "Doc." [_ a &opts v? -v] [a v?])
  (test (x "x" "A" "-v") ["A" "-v"])
  (magi/defcmd [y :rules] "Rules." [& _] [:z 1])
  (test (y :doc) "Rules.")
  (test ((y :rules) "y") [:z 1]))

(deftest magi/synopsis
  (defn doc-of [file]
    (magi/synopsis (path/join dir "magi.d" file)))

  (test (doc-of "described.janet") "A described script.")
  # nix-shell's `#!` lines sit between the shebang and the header.
  (test (doc-of "nix-shell.zsh") "A script provisioned by nix-shell.")
  # A bare TODO is a placeholder, not a description.
  (test (nil? (doc-of "todo.janet")) true)
  (test (nil? (doc-of "does-not-exist.janet")) true)
  # A directory is not a script.
  (test (nil? (magi/synopsis (path/join dir "magi.d"))) true))

(deftest magi/rules->entries
  # Names come from the rule's pattern, aliases are the tail of a keyword
  # tuple, and a pattern is told apart from a command. A pattern with neither
  # keyword nor :name cannot be listed, and a trailing fallback isn't an entry.
  (test (map |[($0 :name) ($0 :aliases) ($0 :kind)]
             (magi/rules->entries
               ['(* "@")     {:doc "Sigil." :name "@*" :exec |[;$&]}
                [:many :m :n] "echo"
                '(* "%")     {:exec |[;$&]}
                "fallback"]))
        @[["@*" [] :pattern] ["many" ["m" "n"] :command]])

  # A bare fn is a command, described by the header of the script it was
  # compiled in, and so is a :rules fn; a :doc beats both. Except the
  # dispatching script's own header, which describes the dispatcher.
  (defn doc-of [dest]
    ((first (magi/rules->entries [:x dest])) :doc))
  (def described (path/abspath (path/join dir "magi.d/described.janet")))
  (def f (get-in (dofile described) ['main :value]))
  (test (doc-of f) "A described script.")
  (test (doc-of {:rules f}) "A described script.")
  (test (doc-of {:doc "Mine." :rules f}) "Mine.")
  (test (with-dyns [:script described] (doc-of f)) "")
  # Builders would have to be run to say what they build; only :doc counts.
  (test (doc-of {:eval |[f ;$&]}) ""))

(deftest magi/header->specs
  # The whole grammar at once, since judge diffs the array. A bracket and a
  # backslash must be escaped, or the spec is unparsable and zsh silently
  # drops the entire completion. "," and "|" both yield one spec per spelling,
  # sharing an exclusion group. zsh evaluates the ((...)) field, so a backtick
  # or $ reaching it unescaped would run a command when the user hits TAB.
  (test (magi/header->specs (path/join dir "magi.d/specs.janet"))
        @["-a[A plain flag, with a bracket \\] and a back\\\\slash.]"
          "(-l --list)-l[Two spellings of one option.]"
          "(-l --list)--list[Two spellings of one option.]"
          "(-e -f -d)-e[Three mutually exclusive options.]"
          "(-e -f -d)-f[Three mutually exclusive options.]"
          "(-e -f -d)-d[Three mutually exclusive options.]"
          "--host[An option taking a value, completed by a function.]:host:magi.comp.hosts"
          ``1:command:((one:"A description with \"quotes\", \$DOLLAR and a \`backtick\`." wm\*:"Column-aligned, and a value needing escapes."))``
          "2:plain: "
          "*:rest:__magi_sync_arg"])

  # The single-line style. "-q" has no description and TODO is a placeholder,
  # so neither becomes a spec.
  (test (magi/header->specs (path/join dir "magi.d/oneline.janet"))
        @["-![Do a dry run.]"
          "(-? -??)-?[Enable debug mode, at increasing verbosity.]"
          "(-? -??)-??[Enable debug mode, at increasing verbosity.]"])

  (test (magi/header->specs (path/join dir "magi.d/undocumented.janet")) @[]))

(deftest magi/header-matches-argspec
  (defn flags-in
    [spec]
    (def out @[])
    (def second (get spec 1))
    (var opts? (or (indexed? second)
                   (and (symbol? second) (string/has-prefix? "-" (string second)))))
    (var flag? false)
    (each item spec
      (cond
        (= item '&opts) (do (set opts? true) (set flag? false))
        (index-of item ['&args '&]) (set opts? false)
        (not opts?) nil
        # Options come in pairs: a binding name, then its spelling(s).
        flag? (do
                (set flag? false)
                (array/push out ;(filter |(string/has-prefix? "-" $0)
                                         (map string (if (indexed? item) item [item])))))
        (set flag? true)))
    out)

  (defn argspec-flags
    "Every option spelling FILE declares, including in nested cmdfn forms."
    [file]
    (def out @[])
    (defn argspec-of [form]
      # defmain has no NAME, and a docstring may sit before the argspec.
      (def tail (slice form (if (= (first form) 'defmain) 1 2)))
      (get tail (if (string? (first tail)) 1 0) []))
    (defn walk [form]
      (when (indexed? form)
        (cond
          (index-of (first form) ['defcmd 'defcmd- 'defmain])
          (array/push out ;(flags-in (argspec-of form)))

          (= (first form) 'cmdfn)
          (array/push out ;(flags-in (get form 1 []))))
        (each item form (walk item))))
    (each form (parse-all (slurp file)) (walk form))
    (distinct out))

  (defn header-flags
    "The option spellings FILE's OPTIONS: header documents."
    [file]
    (def peg ~(* (? (* "(" (thru ")"))) (<- (* "-" (some (if-not "[" 1)))) "["))
    (seq [spec :in (magi/header->specs file)
          :let [match (peg/match peg spec)]
          :when match]
      (first match)))

  # Reported as one list rather than a test per file, so a failure names every
  # offender at once: [command documented-flags declared-flags]
  (def cmds (path/join dir "../../bin/magi.d"))
  (def names [;(os/dir cmds)
              ;(mapcat (fn [sub] (map |(path/join sub $0) (os/dir (path/join cmds sub))))
                       ["ops.d" "wm.d"])])
  (test (seq [name :in (sort (filter |(string/has-suffix? ".janet" $0) names))
              :let [file (path/join cmds name)
                    documented (sorted (header-flags file))
                    declared (sorted (argspec-flags file))]
              :when (not (deep= documented declared))]
          [name documented declared])
        @[]))

(deftest magi/specs-are-well-formed
  # _arguments dies on the *whole* call if any one spec is unparsable
  (def spec-peg
    ~{:esc (* "\\" 1)
      :group (* "(" (any (if-not ")" 1)) ")")
      :desc (any (+ :esc (if-not (set "[]") 1)))
      :field (any (+ :esc (if-not ":" 1)))
      :action (* ":" :field ":" (any 1))
      :option (* (? :group) "-" (some (if-not "[" 1)) "[" :desc "]" (? :action) -1)
      :positional (* (+ (some (range "09")) "*") (between 1 2 ":") :field ":" (any 1) -1)
      :main (+ :option :positional)})

  (defn dispatchable-scripts
    ``Return all dispatchable magi scripts that it can resolve to.``
    []
    (def out @[])
    (defn walk [dir]
      (each name (try (os/dir dir) ([_] []))
        (def file (path/join dir name))
        (case (os/stat file :mode)
          :directory (when (string/has-suffix? ".d" name) (walk file))
          :file (array/push out file))))
    (let [home (path/join dir "../..")]
      (walk (path/join home "bin"))
      (each area ["hosts" "config"]
        (each name (try (os/dir (path/join home area)) ([_] []))
          (walk (path/join home area name "bin"))))
      (sorted out)))

  (test (seq [file :in (dispatchable-scripts)
              spec :in (magi/header->specs file)
              :when (not (peg/match spec-peg spec))]
          [(path/basename file) spec])
        @[]))

(deftest magi/scan
  (def fixtures (path/join dir "magi.d"))

  # cmd.zsh has no description; sub.d is described by .docs; vars.zsh's second
  # line is a bare TODO, which synopsis treats as no description.
  # non-executable-cmd.zsh is skipped b/c it's not executable, and neither are
  # .janet fixtures.
  (test (magi/scan fixtures) @["cmd:" "sub:Hello world" "vars:"])

  # __magi_hooks passes a directory that does not exist on every host.
  (test (magi/scan (path/join dir "does-not-exist") fixtures)
        @["cmd:" "sub:Hello world" "vars:"])

  (deftest "The first directory to define a name wins"
    (test (magi/scan fixtures (path/join fixtures "sub.d"))
          @["cmd:" "sub:Hello world" "vars:" "deeper:Test #2" "nested:"])))
