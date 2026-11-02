#!/usr/bin/env zsh
# A simulation of the completion system, for testing lib/zsh/completions/*.
#
# SYNOPSIS:
#   completion.zsh COMPLETION CASE [WORD...]
#
# COMPLETION names a file in lib/zsh/completions, minus its leading underscore.
# CASE is one of the arms at the bottom. WORDs become $words, spelled the way
# zsh spells them: the whole command line, *including* the word being completed,
# which is usually the empty one at the end. $CURRENT points at it.

emulate -L zsh
# What compinit's _comp_setup guarantees for any real completion.
setopt extendedglob nullglob bareglobqual rcexpandparam unset
setopt no_globsubst no_shwordsplit
local -a reply  # _comp_setup declares this; see the note in _magi's header.

_arguments() { local a; for a in "$@"; do [[ $a == (-C|-A|-\*) ]] && continue; print -r -- "ARG $a"; done }
_describe()  { local t=$2 n=$4 x=$6
               print -r -- "DESC[$t] ${(j: :)${(P)n}}"
               [[ -n $x ]] && print -r -- "DESC[$t] ${(j: :)${(P)x}}"
               return 0 }
_wanted()    { local t=$1; shift 4; print -r -- "WANT[$t] ${(j: :)@}" }
_alternative() { print -r -- "ALT ${(j: :)@}" }
_default()   { print -r -- "DEFAULT" }
_files()     { print -r -- "FILES" }
_command_names() { print -r -- "COMMANDS ${(j: :)@}" }
_hosts()     { print -r -- "HOSTS ${(j: :)@}" }
_remote_files() { print -r -- "REMOTE[${IPREFIX%:}] ${(j: :)@} $PREFIX" }
compadd()    { print -r -- "ADD ${(j: :)@}" }
# globsubst because the real compset takes a pattern, and NO_glob_subst -- which
# _comp_setup sets, and which the builtin is not subject to -- would make `-P
# '*:'` a search for two literal characters.
compset()    { setopt localoptions globsubst
               local p=$@[-1] before=$PREFIX
               [[ $PREFIX == $p* ]] || return 1
               if [[ $# -ge 3 && $2 == <-> ]]; then PREFIX=${PREFIX#$p}
               else                                 PREFIX=${PREFIX##$p}
               fi
               IPREFIX+=${before[1,$#before-$#PREFIX]}
               return 0 }

local root=${0:A:h:h:h}
local completion=$1 case=$2; shift 2
# Every completion falls back to deriving this from its own path, which is not
# where it lives in a test. The shims in path/ are what `command magi` finds; see
# the note in there for why they have to come first.
local -x DOTFILES_HOME=$root
local -x PATH=$root/test/_lib/path:$PATH
# The ops completion asks magi for its help, which is gated on the role in
# info.json. Pin a workstation fixture so the suite does not depend on the
# machine it runs on.
local -x XDG_DATA_HOME=$root/test/magi/ops.d/workstation

# The shared half of every completion comes off $fpath, by the same glob
# modules/magi.nix autoloads it with. Sourcing the completion itself runs it on
# no arguments, which is noise, not an error.
fpath=( $root/lib/zsh $fpath )
autoload -Uz $root/lib/zsh/magi.*(.:t)
source $root/lib/zsh/completions/_$completion >/dev/null 2>&1

local -a _magi_reply _magi_cmd _magi_bindirs _magi_cfgdirs _magi_hookdirs _magi_hookareas
local _magi_root=$root _magi_bin=$completion
local _magi_host _magi_wm _magi_datadir
# The name the completion was invoked for. Only a wrapper makes it interesting.
local service=$completion

# magi is the only one that walks $DOTFILES_HOME, so it's the only one with
# anything to stand in for.
if [[ $completion == magi ]]; then
  _magi_host=testhost
  _magi_wm=testwm
  _magi_datadir=$root/test/_lib/data
  _magi_bindirs=( $root/test/_lib/bin )
  _magi_cfgdirs=( alpha beta )
  _magi_hookdirs=(
    $root/config/alpha/hooks
    $root/hosts/testhost/hooks
    $root/test/_lib/data/hooks.d/beta.d
  )
  _magi_hookareas=( alpha beta host )
fi

# Report what would be dumped rather than running magi, so the command line a
# walk reconstructs is observable.
__driver_nodump() { magi.comp.dump() { print -r -- "DUMP ${(j: :)@}"; return 1 } }
__driver_nomagi()  { magi.comp.scan() { return 1 }; magi.comp.dump() { return 1 } }

words=( "$@" ); CURRENT=$#words; PREFIX=""; IPREFIX=""; SUFFIX=""; line=( "$@" )
case $case in
  (dispatch) magi.comp.dispatch ;;
  (menu) PREFIX=${1-}; magi.comp.commands ;;
  (areas) PREFIX=${1-}; __magi_hook_areas ;;
  # __magi_hook_arg reads the positional that _arguments already consumed out
  # of $line, and $CURRENT as *:: leaves it: 1 for the first of the rest
  # arguments.
  (hookarg)
    __magi_hooks() { print -r -- "HOOKS ${(j: :)@}" }
    line=( ${1-} ); CURRENT=${2:-1}
    __magi_hook_arg
    ;;
  # Which of $_magi_hookdirs a scoped hook menu scans, and what becomes of the
  # NN- prefixes and duplicates the scan hands back. $1 is the area, if any.
  (hooks)
    magi.comp.scan() {
      print -r -- "SCAN ${(j: :)${@#$root/}}"
      _magi_reply=( 10-on-x:first on-x:second 20-on-y:third )
    }
    __magi_hook_areas() { print -r -- "AREAS" }
    __magi_hooks ${1-}
    ;;
  # __magi_sync_arg branches on the command _arguments already matched and counts
  # how far into the rest arguments it is, both of which it reads out of $line:
  # every positional, the word being completed included. $1 is the command.
  (syncarg)
    line=( "$@" ); words=( magi sync "$@" ); CURRENT=$#words
    __magi_sync_arg
    ;;
  # __magi_theme_arg reads the subcommand out of $line, the same way syncarg
  # does, and offers values only for the subcommands that take one.
  (themearg)
    line=( "$@" ); words=( magi theme "$@" ); CURRENT=$#words
    __magi_theme_arg
    ;;
  # The real entry point, on its own terms: it declares its own locals, so these
  # three are the only cases that ignore the fixtures above.
  (top) _$completion ;;
  # Same, but standing in for `compdef NAME _magi`. zsh looks a completion up by
  # the command's basename, so that -- and not $words[1] -- is what $service is.
  (wrapper|wrapper-dump)
    [[ $case == wrapper-dump ]] && __driver_nodump
    # A wrapper's search path comes from _magi itself, so the fixture tree has to
    # *be* $DOTFILES_HOME for the walk to land in it.
    DOTFILES_HOME=$root/test/_lib
    service=${words[1]:t}
    _$completion
    ;;
  (reconstruct) __driver_nodump; magi.comp.dispatch ;;
  # One completer by name, for the @refs nothing else in here reaches: $1 names
  # it, $2 is the word so far.
  (call) PREFIX=${2-}; $1 ;;
  # What magi.comp.scriptdir leaves in $_magi_leaf for a leaf's @refs to find.
  (leaf)
    magi.comp.dump() { _magi_reply=( '*:: :__magi_cobra' ) }
    _arguments() { print -r -- "LEAF ${(j: :)_magi_leaf}" }
    magi.comp.dispatch
    ;;
  # __magi_cobra against a fixture that answers __complete. $1 is the directive
  # it should end on (suffixed "empty" for no candidates); the rest are the
  # words after the script's name.
  (cobra)
    local -x COBRA_DIRECTIVE=$1; shift
    local -a _magi_leaf=( $root/test/magi/completion.d/cobra )
    _describe() { print -r -- "DESC ${(j:|:)@} = ${(j:|:)${(P)4}}" }
    words=( "$@" ); CURRENT=$#words; PREFIX=$words[-1]
    __magi_cobra
    ;;
  # Every path must degrade rather than error if the binary is unavailable
  (nomagi) __driver_nomagi; magi.comp.dispatch ;;
  (*) print -r -- "unknown case: $case"; return 2 ;;
esac
