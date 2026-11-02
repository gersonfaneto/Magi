#!/usr/bin/env zsh

# Stop TRAMP (in Emacs) from hanging or term/shell from echoing back commands
if [[ $TERM == dumb || -n $INSIDE_EMACS ]]; then
  unsetopt zle prompt_cr prompt_subst
  whence -w precmd >/dev/null && unfunction precmd
  whence -w preexec >/dev/null && unfunction preexec
  PS1='$ '
fi

## Bootstrap interactive session
if [[ $TERM != dumb ]]; then
  if [[ -r ${XDG_CACHE_HOME}/p10k-instant-prompt-${(%):-%n}.zsh ]]; then
    source ${XDG_CACHE_HOME}/p10k-instant-prompt-${(%):-%n}.zsh
  fi

  ## ZSH configuration
  # Treat these characters as part of a word.
  WORDCHARS='-*?[]~&.;!#$%^(){}<>'
  unsetopt BRACE_CCL        # Allow brace character class list expansion.
  setopt COMBINING_CHARS    # Combine zero-length punc chars (accents) with base char
  setopt RC_QUOTES          # Allow 'Henry''s Garage' instead of 'Henry'\''s Garage'
  setopt HASH_LIST_ALL
  unsetopt CORRECT_ALL
  unsetopt NOMATCH
  unsetopt MAIL_WARNING     # Don't print a warning message if a mail file has been accessed.
  unsetopt BEEP             # Hush now, quiet now.
  setopt IGNOREEOF
  unsetopt CASE_GLOB
  ## Jobs
  setopt LONG_LIST_JOBS     # List jobs in the long format by default.
  setopt AUTO_RESUME        # Attempt to resume existing job before creating a new process.
  setopt NOTIFY             # Report status of background jobs immediately.
  unsetopt BG_NICE          # Don't run all background jobs at a lower priority.
  unsetopt HUP              # Don't kill jobs on shell exit.
  unsetopt CHECK_JOBS       # Don't report on jobs when shell exit.
  ## History
  HISTORY_SUBSTRING_SEARCH_PREFIXED=1
  HISTORY_SUBSTRING_SEARCH_FUZZY=1
  HISTSIZE=100000   # Max events to store in internal history.
  SAVEHIST=100000   # Max events to store in history file.
  setopt BANG_HIST                 # History expansions on '!'
  setopt EXTENDED_HISTORY          # Include start time in history records
  setopt APPEND_HISTORY            # Appends history to history file on exit
  setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
  setopt SHARE_HISTORY             # Share history between all sessions.
  setopt HIST_EXPIRE_DUPS_FIRST    # Expire a duplicate event first when trimming history.
  setopt HIST_IGNORE_DUPS          # Do not record an event that was just recorded again.
  setopt HIST_IGNORE_ALL_DUPS      # Remove old events if new event is a duplicate
  setopt HIST_FIND_NO_DUPS         # Do not display a previously found event.
  setopt HIST_IGNORE_SPACE         # Do not record an event starting with a space.
  setopt HIST_SAVE_NO_DUPS         # Do not write a duplicate event to the history file.
  setopt HIST_REDUCE_BLANKS        # Minimize unnecessary whitespace
  setopt HIST_VERIFY               # Do not execute immediately upon history expansion.
  setopt HIST_BEEP                 # Beep when accessing non-existent history.
  ## Directories
  DIRSTACKSIZE=9
  unsetopt AUTO_CD            # Implicit CD slows down plugins
  setopt AUTO_PUSHD           # Push the old directory onto the stack on cd.
  setopt PUSHD_IGNORE_DUPS    # Do not store duplicates in the stack.
  setopt PUSHD_SILENT         # Do not print the directory stack after pushd or popd.
  unsetopt PUSHD_TO_HOME      # Don't push to $HOME when no argument is given.
  setopt CDABLE_VARS          # Change directory to a path stored in a variable.
  setopt MULTIOS              # Write to multiple descriptors.
  unsetopt GLOB_DOTS
  unsetopt AUTO_NAME_DIRS     # Don't add variable-stored paths to ~ list

  ## Plugin configuration
  if (( $+commands[fd] )); then
    export FZF_DEFAULT_OPTS="--reverse --ansi"
    export FZF_DEFAULT_COMMAND="fd ."
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND="fd -t d . $HOME"
  fi
  # fzf reads this file on every invocation, so palette switches are live.
  if (( $+commands[fzf] )) && [[ -r ${XDG_CONFIG_HOME}/fzf/theme.opts ]]; then
    export FZF_DEFAULT_OPTS_FILE=${XDG_CONFIG_HOME}/fzf/theme.opts
  fi
  # bat
  if (( $+commands[bat] )); then
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
    export MANROFFOPT='-c'
  fi
  # zsh-vi-mode
  export ZVM_INIT_MODE=sourcing
  export ZVM_VI_ESCAPE_BINDKEY=^G
  export ZVM_LINE_INIT_MODE=i
  # zsh-autosuggest
  export ZSH_AUTOSUGGEST_MANUAL_REBIND=1

  ## Bootstrap zpm
  export ZPM_DIR="${ZPM_DIR:-${XDG_DATA_HOME:-~/.local/share}/zpm}"
  if [[ ! -f $ZPM_DIR/zpm.zsh ]] && (( $+commands[git] )); then
    echo "Installing zpm-zsh/zpm"
    git clone --recursive https://github.com/zpm-zsh/zpm "$ZPM_DIR"
  fi
  [[ -f $ZPM_DIR/zpm.zsh ]] && source $ZPM_DIR/zpm.zsh

  if (( $+commands[fzf] )); then
      # fzf-share is a nixpkgs-ism
    magi.cache fzf --zsh 2>/dev/null || if (( $+commands[fzf-share] )); then
      source "$(fzf-share)/key-bindings.zsh"
      source "$(fzf-share)/completion.zsh"
    fi
  fi

  # No git, no network, or a first run on a host I've infected: no plugins, and
  # the rest of this file still has to work. $functions, not $commands -- zpm
  # is a shell function, so $commands would never have found it, plugins or no.
  if (( $+functions[zpm] )); then
    # One `zpm load` per plugin, deliberately: load order is important to ensure
    # these packages cooperate.
    zpm load jeffreytse/zsh-vi-mode
    zpm load zdharma-continuum/fast-syntax-highlighting
    # No `fpath:/src` needed (it'll break zpm, which finds the completions there
    # on its own).
    zpm load zsh-users/zsh-completions
    zpm load zsh-users/zsh-autosuggestions
    zpm load dxrcy/zsh-history-substring-search
    zpm load romkatv/powerlevel10k
    zpm load hlissner/zsh-autopair
  elif (( ! $+functions[compdef] )); then
    # Without zpm, nobody runs compinit, so...
    autoload -Uz compinit
    compinit -i -C -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-$ZSH_VERSION"
  fi

  # zpm compiles its own (and fpath), but my zsh libs must be compiled manually.
  magi.load ${${(%):-%x}:A:h}/{completion,keybinds,aliases,prompt}.zsh

  ## Palette-driven shell theming
  # theme.py renders these from the active bundle (see modules/shell/zsh.nix).
  # The prompt file has to come after prompt.zsh, which unsets every
  # POWERLEVEL9K_* parameter at the top of its config function.
  typeset -g __magi_theme_dir=${XDG_CONFIG_HOME:-$HOME/.config}/zsh
  typeset -gA __magi_theme_seen
  typeset -ga __magi_theme_files=(
    $__magi_theme_dir/theme.p10k.zsh
    $__magi_theme_dir/theme.fsh.zsh
    $__magi_theme_dir/theme.autosuggest.zsh
  )
  zmodload -F zsh/stat b:zstat

  # zstat is a builtin, so the watch below costs no forks per prompt.
  typeset -g __magi_theme_m
  __magi_theme_mtime() {
    local -a mtime
    zstat -A mtime +mtime -- $1 2>/dev/null || return 1
    __magi_theme_m=$mtime[1]
  }

  __magi_theme_source() {
    local f
    for f in $__magi_theme_files(N); do
      __magi_theme_mtime $f && __magi_theme_seen[$f]=$__magi_theme_m
      # The styles assign into an array the plugin declares, so only apply them
      # when fast-syntax-highlighting actually loaded (no zpm, no network).
      if [[ ${f:t} == theme.fsh.zsh ]] && (( ! ${+parameters[FAST_HIGHLIGHT_STYLES]} )); then
        continue
      fi
      source $f
    done
  }

  __magi_theme_dircolors() {
    local db=$__magi_theme_dir/dircolors.theme
    if [[ -r $db ]]; then
      eval "$(dircolors -b $db 2>/dev/null)"
    else
      eval "$(dircolors -b 2>/dev/null)"
    fi
  }

  # Repaint already-open shells when `magi theme` rewrites the palette. Runs
  # after p10k's own precmd (which saves $?), and hands $? back untouched for
  # whatever hook follows.
  __magi_theme_watch() {
    local ret=$? f
    local -a stale
    for f in $__magi_theme_files(N); do
      __magi_theme_mtime $f || continue
      (( __magi_theme_m > ${__magi_theme_seen[$f]:-0} )) && stale+=($f)
    done
    if (( $#stale )); then
      __magi_theme_source
      __magi_theme_dircolors
      (( $+functions[p10k] )) && p10k reload
    fi
    return $ret
  }

  __magi_theme_source
  __magi_theme_dircolors
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd __magi_theme_watch

  magi.cache zoxide init zsh
  (( $+functions[autopair-init] )) && autopair-init

  # CD-able vars
  cfg=~/.config
fi
