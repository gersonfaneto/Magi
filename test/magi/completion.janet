#!/usr/bin/env janet
# Regression tests for lib/zsh/completions/_magi, and for the magi.comp.*
# functions in lib/zsh it's built from.
#
# Everything here fails silently in real life: a broken completion offers
# nothing, and TAB just doesn't do anything.

(use judge)
(use sh)
(import magi :as h)
(import ./../_lib/completion :prefix "")

(def- shim (h/path :home "test/_lib/path/magi"))

(defn- magi [case & words] (complete "magi" case ;words))
(defn- dumped [& words]
  (find |(string/has-prefix? "DUMP " $0) (magi "reconstruct" ;words)))


(deftest completion/subcommand-arguments
  # From bin/magi.d/sync.janet's comment header (OPTIONS: and ARGUMENTS:).
  (def out (magi "dispatch" "sync" ""))
  (test (offers? out "--fast[") true)
  (test (offers? out "build-image:") true))

(deftest completion/sync-arg
  # A position in ARGUMENTS: is absolute, so a value list on `2` would offer
  # itself after every command. What varies with the first argument has to go
  # through the @ref instead, which is what @sync-arg is for.
  (test (magi "syncarg" "build-image" "") @["WANT[variants] -a variants"])
  # Only the first of them; the rest are nixos-rebuild's.
  (test (magi "syncarg" "build-image" "iso" "") @[])
  # Commands that take no such thing are left to zsh.
  (test (magi "syncarg" "switch" "") @["DEFAULT"]))

(deftest completion/theme
  # theme dispatches to its own subcommands, so the header declares one rest
  # argument and __magi_theme_arg picks the values. A second `*` entry makes
  # zsh reject the whole command with "doubled rest argument definition".
  (def out (magi "dispatch" "theme" ""))
  (test (length (filter |(string/find "*:" $0) out)) 1)
  (test (last out) "ARG *:args:__magi_theme_arg"))

(deftest completion/theme-arg
  (test (offers? (magi "themearg" "") "theme-commands") true)
  (test (magi "themearg" "bg" "") @["WANT[backgrounds] light dark"])
  (test (magi "themearg" "source" "")
        @["WANT[modes] scheme dynamic"])
  (test (magi "themearg" "set" "") @["WANT[schemes] -a schemes"])
  # Past the one value these subcommands take, zsh is on its own.
  (test (magi "themearg" "set" "nano" "") @[])
  (test (magi "themearg" "list" "") @[]))

(deftest completion/ssh-target
  # @ssh-target completes both halves of `lab fs [user@]host[:/path]`, ala _ssh
  (test (magi "call" "__magi_ssh_target" "") @["HOSTS -qS:"])
  (test (magi "call" "__magi_ssh_target" "root@") @["HOSTS -qS:"])
  (test (magi "call" "__magi_ssh_target" "root@nas0.lan:/mnt/ap")
        @["REMOTE[root@nas0.lan] -- ssh /mnt/ap"])
  # Only the first colon belongs to the host.
  (test (magi "call" "__magi_ssh_target" "nas0.lan:/mnt/a:b/")
        @["REMOTE[nas0.lan] -- ssh /mnt/a:b/"]))

(deftest completion/ops
  # ops is a nested table, completed as the script directory it's also laid out
  # as: the menu off the scripts in it, each one's arguments off its header.
  (test (offers? (magi "dispatch" "ops" "") "push-keys:Give SYSTEM") true)
  (test (dumped "ops" "push" "") "DUMP ops push")
  # magi ops edit takes SYSTEM:FILE rather than a bare SYSTEM, so it's the one
  # command in there with a completer of its own. The @ref in its header and the
  # function in _magi have to agree on a name, and nothing else notices when
  # they stop agreeing.
  (test (last (magi "dispatch" "ops" "edit" "")) "ARG *:target:__magi_edit_target")
  (test (magi "call" "__magi_edit_target" "") @["WANT[hosts] -S : -a hosts"])
  # Past the colon there's a whole other machine, so nothing.
  (test (magi "call" "__magi_edit_target" "box:") @[]))

(deftest completion/wm
  # magi wm's compiled commands live in bin/magi.d/wm.d, not config/$WM/bin, so
  # _magi has to scan both or they drop off the menu. (The fixture has no
  # config/testwm, so the compiled half is all there is.)
  (test (magi "dispatch" "wm" "") @["DESC[scripts] play-sound:Plays a notification sound."])
  (test (last (magi "dispatch" "wm" "play-sound" ""))
        ``ARG 1:name:((ls:"List the available sounds instead of playing one."))``))

(deftest completion/hook-areas
  # The menu carries the sigil, so areas and hooks can share it; past the
  # sigil, the areas are bare.
  (test (magi "areas" "") @["DESC[areas] @alpha @beta @host"])
  (test (magi "areas" "@") @["DESC[areas] alpha beta host"])
  # A consumed @AREA leaves the hook name to the rest arguments.
  (test (magi "hookarg" "@alpha") @["HOOKS alpha"])
  (test (magi "hookarg" "on-reload") @["DEFAULT"]))

(deftest completion/hooks
  # @AREA picks its dirs the way hook.janet's area-of does: the owner of a
  # hooks/ dir, host for hosts/*/hooks, NAME for a fragment's hooks.d/NAME.d.
  (test (magi "hooks" "alpha") @["SCAN config/alpha/hooks" "DESC[hooks] on-x:first on-y:third"])
  (test (first (magi "hooks" "host")) "SCAN hosts/testhost/hooks")
  (test (first (magi "hooks" "beta")) "SCAN test/_lib/data/hooks.d/beta.d")
  # Unscoped, every dir, and the areas share the menu.
  (test (magi "hooks")
        @["SCAN config/alpha/hooks hosts/testhost/hooks test/_lib/data/hooks.d/beta.d"
          "DESC[hooks] on-x:first on-y:third"
          "AREAS"]))

(deftest completion/paths-are-not-dot-commands
  (test (magi "dispatch" "./foo" "") @["DEFAULT"]))

(deftest completion/command-reconstruction
  # magi.comp.scriptdir has to rebuild the command line for `magi help --dump`. The
  # sigil belongs to the first word whether the NAME.d walk consumes it or it is
  # the leaf, and @DIR must keep its sigil while wm and host do not.
  (test (dumped ".nest" "deep" "") "DUMP .nest deep")
  (test (dumped "wm" "solo" "") "DUMP wm solo")
  (test (dumped "@alpha" "solo" "") "DUMP @alpha solo"))

(deftest completion/script-listing
  # The .NAME sigil lists the bin directories; @DIR the config directories.
  (test (magi "menu" ".") @["DESC[scripts] nest: solo:A fixture script."])
  (test (magi "menu" "@") @["WANT[directories] -a _magi_cfgdirs"]))

(deftest completion/a-matched-rule-is-an-answer
  # host, wm, @DIR and .NAME all consume $words[1] before they walk. A rule that
  # matched and came up empty must not fall through to "read its header", or magi
  # gets asked about whatever is left in $words[1] -- here, nothing at all.
  (test (magi "reconstruct" "host" "") @[]))

(deftest completion/degrades-without-magi
  (test (magi "nomagi" "sync" "") @[])
  (test (magi "nomagi" ".solo" "") @["DEFAULT"]))

(deftest completion/empty-word-is-not-a-bare-dump
  # `magi '' <TAB>` must not run a bare `magi help --dump`. The canary has to be a
  # command that still exists, or this passes by never finding anything.
  (def out (magi "dispatch" "" ""))
  (test (offers? out "sync:Rebuild this flake") false)
  # ...and the same word does come back from a dump that was asked for.
  (test (offers? (magi "menu" "") "sync:Rebuild this flake") true))

(deftest completion/wrapped-commands
  # `compdef NAME _magi` is the whole story for a `exec magi .NAME "$@"` wrapper
  # (like bin/lab): the menu is the wrapper's own script directory, and a
  # leaf's arguments are dumped through the sigil magi resolves it by.
  (test (magi "wrapper" "nest" "") @["DESC[scripts] deep:A nested fixture script."])
  (test (find |(string/has-prefix? "DUMP " $0) (magi "wrapper-dump" "nest" "deep" ""))
        "DUMP .nest deep"))

(deftest completion/cobra
  # @cobra asks the script itself for `__complete WORDS... PREFIX`, by path
  # rather than through magi, which would have eaten the -h. The colon in a
  # value has to be escaped for _describe; the one before a description not.
  (test (magi "cobra" "0" "run" "-h" "")
        @["DESC -t|cobra|argument|_magi_reply = image\\:tag:An image|argv\\:run,-h,"])
  # NoSpace
  (test (magi "cobra" "2" "run" "-h" "")
        @["DESC -t|cobra|argument|_magi_reply|-S| = image\\:tag:An image|argv\\:run,-h,"])
  # Error, and NoFileComp with nothing to offer, are both nothing; without
  # NoFileComp, nothing is zsh's to fill in.
  (test (magi "cobra" "1" "run" "") @[])
  (test (magi "cobra" "4empty" "run" "") @[])
  (test (magi "cobra" "0empty" "run" "") @["DEFAULT"])
  # It finds the script by the command line that reached it, which *:: has
  # sliced off $words by the time it runs.
  (test (magi "leaf" ".nest" "deep" "x" "") @["LEAF .nest deep"])
  (test (magi "leaf" "wm" "solo" "") @["LEAF wm solo"])
  # The wrapper tests can't reach bin/lab.d (they walk a fixture tree), so pin
  # the other end of the @ref here: lab docker, and its dk alias, ask for it.
  (each name [".lab docker" ".lab dk"]
    (def out ($<_ ,shim help --dump ,;(string/split " " name)))
    (test (last (string/split "\n" out)) "*::args:__magi_cobra")))
