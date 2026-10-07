#!/usr/bin/env zsh
# Install this flake onto a machine, guiding where it needs to.
#
# SYNOPSIS:
#   install.zsh [--root DIR] [--host NAME] [--user NAME] [--role ROLE]
#     [--desktop NAME] [--networks "A B"] [--hardware "A B"] [--disk DEV]
#     [--swap-size SIZE] [--disko-config FILE] [--no-disko] [--yes]
#     [--dry-run] [--force]
#   nix --extra-experimental-features "nix-command flakes" --option accept-flake-config true run github:gersonfaneto/Magi#install
#
# DESCRIPTION:
#   Run this from the nixos installer. It stages the flake outside the target,
#   then either installs an existing config under hosts/ or scaffolds a new one
#   (asking for hostname, user, role, disk, and passwords), partitions the
#   target with disko, lays the checkout onto it, and runs nixos-install.
#   Anything it wasn't told, it asks for -- unless --yes, in which case
#   missing answers are fatal.
#
#   New hosts are written as uncommitted files under hosts/NAME/ in the fresh
#   clone: review them, then commit when happy. Only hosts/NAME/ and the shared
#   installer/ modules matter; hosts/ is otherwise a whitelist (see
#   hosts/README.md).
#
# ENVIRONMENT:
#   MAGI_REPO
#     Clone from here instead of github (mirrors, testing). Must serve this
#     same flake.
#
# OPTIONS:
#   --root DIR
#     Where the target system is mounted. Default: /mnt
#   --host NAME
#     Which config under hosts/ to install. Asked for if omitted. If it names
#     no existing host, a new one is scaffolded.
#   --user NAME
#     Primary user of the new system. Asked for if omitted (new hosts only;
#     existing hosts declare their own user and a mismatch aborts).
#   --role ROLE
#     workstation or server. Asked for if omitted (new hosts only).
#   --desktop NAME
#     Desktop for a workstation (e.g. hyprland). Asked for if omitted, empty
#     for none (new hosts only).
#   --networks "A B"
#     Space-separated networks (new hosts only). Asked for if omitted.
#   --hardware "A B"
#     Space-separated hardware profiles, e.g. "cpu/amd gpu/amd wifi ssd".
#     Asked for if omitted (new hosts only).
#   --disk DEV
#     Target disk for disko, e.g. /dev/nvme0n1. Asked for when needed. Refused
#     if the host already pins its own disko.nix.
#   --swap-size SIZE
#     Swap partition size for the default layout, e.g. 8G or 512M.
#     Default: 8G.
#   --disko-config FILE
#     Use this disko config instead of the host's (or default) layout.
#   --no-disko
#     Skip disko: partition and mount the target by hand first (for hosts
#     whose disks disko doesn't manage).
#   --yes
#     Answer yes to confirmations. Missing values still abort.
#   --dry-run
#     Prompt as usual, print the plan and rendered files, change nothing.
#   --force
#     Run even when this doesn't look like the nixos installer (for VMs/tests).
#
# EXIT CODES:
#   1  not root, not the installer, a command failed, or the user bailed
#   2  bad, missing, or unanswerable argument

readonly REPO=${MAGI_REPO:-https://github.com/gersonfaneto/Magi}
readonly DEST=/etc/magi
# $0 is the function name inside functions (FUNCTION_ARGZERO), so capture the
# script path here, at top level, while it still means the script.
readonly SCRIPT="$0"

# NOTE: keep this script to basic glob patterns only (no extendedglob `#`/`##`
# operators): they parse only once extendedglob is active, which `zsh -n`
# never is, and this file is syntax-checked that way.

_diex() {  # CODE MESSAGE...
  local code=$1; shift
  >&2 print -r -- "Error: $*"
  exit $code
}

_usage() {
  >&2 sed -n '2,/^$/{/^#/!d; s/^# \?//; p}' "$SCRIPT"
}

_variant() {
  ( . /etc/os-release 2>/dev/null; print -r -- "${VARIANT_ID-}" )
}

_hosts() {  # FLAKE -> prints host names, one per line
  local d
  for d in "$1"/hosts/*/default.nix; do
    [[ -f $d ]] || continue
    print -r -- "${d:h:t}"
  done
}

# Reads one line from the terminal (after printing PROMPT there) and echoes
# it on stdout, so callers capture it:  VALUE=$(_tty_read "Prompt: ").
# Assigning caller variables from inside a function is not portable zsh
# (namerefs need ksh emulation; typeset -g is shadowed by caller locals), so
# nothing here assigns outside its own scope. Fails quietly with no terminal.
_tty_read() {  # [-s] PROMPT
  local silent=0
  [[ ${1-} == -s ]] && { silent=1; shift; }
  [[ -c /dev/tty ]] || return 1
  print -rn -- "$1" > /dev/tty || return 1
  local answer
  if (( silent )); then
    IFS= read -rs answer < /dev/tty || return 1
    print -r -- "" > /dev/tty
  else
    IFS= read -r answer < /dev/tty || return 1
  fi
  print -r -- "$answer"
}

_ask() {  # FLAG PROMPT [DEFAULT] -- echo answer; fail 2 if unanswerable/empty
  local flag=$1 prompt=$2 default=$3 answer
  answer=$(_tty_read "$prompt${default:+ [$default]}: ") \
    || { print -r -- "Error: nothing to ask on; pass --$flag" >&2; return 2; }
  answer="${answer:-$default}"
  if [[ -z $answer ]]; then
    print -r -- "Error: --$flag can't be empty" >&2; return 2
  fi
  print -r -- "$answer"
}

_ask_opt() {  # FLAG PROMPT (empty answers allowed, for optional values)
  local flag=$1 prompt=$2 answer
  answer=$(_tty_read "$prompt: ") \
    || { print -r -- "Error: nothing to ask on; pass --$flag" >&2; return 2; }
  print -r -- "$answer"
}

_ask_secret() {  # NAME PROMPT -- echo answer; fail on mismatch/empty/no-tty
  local name=$1 prompt=$2 one two
  one=$(_tty_read -s "$prompt: ") \
    || { print -r -- "Error: no answer for $name" >&2; return 2; }
  two=$(_tty_read -s "Repeat $prompt: ") \
    || { print -r -- "Error: no answer for $name" >&2; return 2; }
  # Quoted: passwords with glob characters must compare literally.
  [[ $one == "$two" ]] || { print -r -- "Error: $name mismatch; run again" >&2; return 1; }
  [[ -n $one ]] || { print -r -- "Error: $name can't be empty" >&2; return 2; }
  print -r -- "$one"
}

_confirm() {  # MESSAGE... (type the hostname, unless --yes)
  (( YES )) && return 0
  [[ -c /dev/tty ]] || _diex 2 "no terminal to confirm on; pass --yes"
  local answer
  print -r -- "$*"
  read -r "answer?Type '$host' to continue: " < /dev/tty \
    || _diex 1 "bailed"
  [[ $answer == "$host" ]] || _diex 1 "bailed"
}

_valid_name() {  # VALUE WHAT (lowercase, digits, interior dashes)
  case $1 in
    ""|*[!a-z0-9-]*|-*|*-)
      _diex 2 "$2 '$1': use lowercase letters, digits, and dashes" ;;
  esac
}

_valid_list() {  # VALUE WHAT (space-separated profile tokens)
  # No literal space inside the brackets: zsh won't parse it in a pattern.
  case $1 in
    *[!a-z0-9/[:space:]]*)
      _diex 2 "$2 '$1': space-separated, lowercase letters, digits, slashes" ;;
  esac
}

_quote_list() {  # VALUE -> '"a" "b"' (VALUE already validated)
  local x out=""
  for x in ${=1}; do out="$out\"$x\" "; done
  print -r -- "${out% }"
}

main() {
  local -a args
  local arg
  for arg in "$@"; do
    if [[ $arg == --*=* ]]; then
      args+=( "${arg%%=*}" "${arg#*=}" )
    else
      args+=( "$arg" )
    fi
  done
  set -- "${args[@]}"

  local -a o_root o_host o_user o_role o_desktop o_networks o_hardware
  local -a o_disk o_swap o_disko_config o_nodisko o_yes o_dryrun o_force o_help
  zparseopts -D -F -- \
    -root:=o_root -host:=o_host -user:=o_user -role:=o_role \
    -desktop:=o_desktop -networks:=o_networks -hardware:=o_hardware \
    -disk:=o_disk -swap-size:=o_swap -disko-config:=o_disko_config \
    -no-disko=o_nodisko -yes=o_yes -dry-run=o_dryrun -force=o_force \
    h=o_help -help=o_help || { _usage; exit 2 }
  (( $#o_help )) && { _usage; exit 0 }

  local root="${o_root[2]:-/mnt}"
  local host="${o_host[2]}"
  local user="${o_user[2]}"
  local role="${o_role[2]}"
  local desktop="${o_desktop[2]}"
  local networks="${o_networks[2]}"
  local hardware="${o_hardware[2]}"
  local disk="${o_disk[2]}"
  local swap="${o_swap[2]:-8G}"
  local disko_config="${o_disko_config[2]}"
  local flake="$root$DEST" hostdir new_host=0
  typeset -g YES=$#o_yes DRY=$#o_dryrun

  (( EUID == 0 )) || _diex 1 "must be run as root"
  if (( ! $#o_force )) && [[ "$(_variant)" != installer ]]; then
    _diex 1 "this isn't the nixos installer, and I'd rather not install over a live system (or pass --force)"
  fi
  case $swap in
    [0-9]*[GM]) ;;
    *) _diex 2 "--swap-size '$swap': e.g. 8G or 512M" ;;
  esac
  if (( $#o_nodisko )) && { [[ -n $disko_config || -n $disk ]] || (( $#o_swap )); }; then
    _diex 2 "--no-disko conflicts with --disk/--disko-config/--swap-size"
  fi

  # nixos-install --flake evaluates the flake, so make sure flakes are on no
  # matter what the installer's nix.conf says (the clone itself is plain git).
  export NIX_CONFIG="${NIX_CONFIG-}
experimental-features = nix-command flakes
accept-flake-config = true"

  if (( DRY )); then
    print -r -- "Dry run: answering prompts, changing nothing."
  fi

  ## 1. Clone into staging, outside $root: disko mounts fresh filesystems
  # over $root later, which would wipe a checkout made directly there.
  local src
  src="$(mktemp -d)" || _diex 1 "couldn't make a staging dir"
  if [[ -d $flake/.git ]]; then
    print -r -- "Using the checkout already at $flake"
    cp -a "$flake/." "$src/" || _diex 1 "couldn't stage $flake"
  else
    git clone --recursive "$REPO" "$src" || _diex 1 "couldn't clone $REPO"
  fi

  ## 2. Host: existing or scaffolded
  if [[ -z $host ]]; then
    print -r -- "Hosts in this flake:"
    _hosts "$src" | sed 's/^/  /'
    print -r -- "Name a new host to scaffold one."
    host=$(_ask host Hostname) || exit $?
  fi
  _valid_name "$host" "hostname"
  hostdir="$src/hosts/$host"
  if [[ -f $hostdir/default.nix ]]; then
    print -r -- "Installing existing host '$host'"
  else
    new_host=1
    print -r -- "Scaffolding new host '$host' (uncommitted, under $hostdir)"
    [[ -n $user ]] || { user=$(_ask user Username gerson) || exit $?; }
    _valid_name "$user" "username"
    if [[ -z $role ]]; then
      role=$(_ask role "Role (workstation/server)" workstation) || exit $?
    fi
    [[ $role == workstation || $role == server ]] \
      || _diex 2 "--role '$role': workstation or server"
    if [[ $role == workstation ]] && (( ! $#o_desktop )); then
      desktop=$(_ask_opt desktop "Desktop (hyprland, empty for none)") || exit $?
    fi
    (( $#o_networks )) || { networks=$(_ask_opt networks "Networks (space-separated, empty for none)") || exit $?; }
    _valid_list "$networks" "--networks"
    (( $#o_hardware )) || { hardware=$(_ask_opt hardware "Hardware profiles (space-separated, empty for none)") || exit $?; }
    _valid_list "$hardware" "--hardware"
  fi

  # An existing host owns its config; scaffold-only flags passed alongside
  # one are mistakes, not overrides. (--user is checked against the host's
  # declared user just below instead.)
  if (( ! new_host )); then
    (( $#o_role )) && _diex 2 "--role is for scaffolding new hosts; '$host' declares its own"
    (( $#o_desktop )) && _diex 2 "--desktop is for scaffolding new hosts; '$host' declares its own"
    (( $#o_networks )) && _diex 2 "--networks is for scaffolding new hosts; '$host' declares its own"
    (( $#o_hardware )) && _diex 2 "--hardware is for scaffolding new hosts; '$host' declares its own"
  else
    [[ $role == workstation ]] || { (( $#o_desktop )) && [[ -n $desktop ]] && _diex 2 "--desktop with --role server: servers have no desktop"; }
  fi

  # An existing host owns its user; don't let a stray --user lie about it.
  # (Folded to one line first: profiles blocks span lines in real hosts.)
  if (( ! new_host )) && [[ -n $user ]]; then
    local declared
    declared=$(tr '\n' ' ' < "$hostdir/default.nix" \
      | grep -o 'profiles = {[^}]*user = "[^"]*"' \
      | grep -o 'user = "[^"]*"' | head -1 | cut -d'"' -f2) || declared=""
    if [[ -n $declared && $declared != "$user" ]]; then
      _diex 2 "--user '$user' but '$host' declares '$declared'"
    fi
  fi

  ## 3. Disk
  local disko_cfg=""
  if (( $#o_nodisko )); then
    (( new_host )) && _diex 2 "--no-disko with a new host: scaffold needs disko; partition first, write the host, re-run"
    mountpoint -q "$root" \
      || _diex 1 "nothing is mounted at $root -- partition and mount the target first (or drop --no-disko)"
    print -r -- "Manual partitioning: using what's mounted at $root"
  elif [[ -n $disko_config ]]; then
    [[ -f $disko_config ]] || _diex 2 "--disko-config '$disko_config': no such file"
    disko_cfg="$disko_config"
  elif [[ -f $hostdir/disko.nix ]]; then
    [[ -n $disk ]] && _diex 2 "--disk with '$host': it pins its own disko.nix; edit that (or pass --disko-config)"
    (( $#o_swap )) && _diex 2 "--swap-size with '$host': it pins its own disko.nix; edit that (or pass --disko-config)"
    disko_cfg="$hostdir/disko.nix"
  else
    # No layout yet: default single-disk, or ask.
    if (( new_host )) || [[ -n $disk ]]; then
      [[ -n $disk ]] || { disk=$(_ask disk "Target disk (disko will wipe it, e.g. /dev/nvme0n1)") || exit $?; }
      [[ -b $disk ]] || _diex 2 "--disk '$disk': not a block device"
      if (( new_host )); then
        disko_cfg="$hostdir/disko.nix"
      else
        disko_cfg="$(mktemp)"
        print -r -- "Default layout, rendered to $disko_cfg"
      fi
    elif (( YES )) || [[ ! -c /dev/tty ]]; then
      _diex 2 "'$host' has no disko.nix: pass --disk, --disko-config, or --no-disko"
    else
      print -r -- "'$host' has no disko.nix."
      local mode
      print -r -- "  1) default single-disk layout (ESP + swap + root)"
      print -r -- "  2) custom disko config file"
      print -r -- "  3) manual partitioning (mount at $root first)"
      mode=$(_ask mode "Partition how? [1]" 1) || exit $?
      case $mode in
        1) disk=$(_ask disk "Target disk (disko will wipe it, e.g. /dev/nvme0n1)") || exit $?
           [[ -b $disk ]] || _diex 2 "--disk '$disk': not a block device"
           disko_cfg="$(mktemp)" ;;
        2) disko_config=$(_ask disko_config "Disko config file") || exit $?
           [[ -f $disko_config ]] || _diex 2 "--disko-config '$disko_config': no such file"
           disko_cfg="$disko_config" ;;
        3) mountpoint -q "$root" \
             || _diex 1 "nothing is mounted at $root -- partition and mount it, then re-run with --no-disko" ;;
        *) _diex 2 "pick 1, 2, or 3" ;;
      esac
    fi
  fi

  ## 4. Passwords (new hosts only; existing hosts own theirs)
  local user_hash="" root_hash=""
  if (( new_host )); then
    local pw
    pw=$(_ask_secret password "Password for $user") || exit $?
    user_hash=$(printf '%s' "$pw" | mkpasswd -m sha-512 -s) \
      || _diex 1 "couldn't hash the password"
    pw=$(_ask_secret password "Password for root") || exit $?
    root_hash=$(printf '%s' "$pw" | mkpasswd -m sha-512 -s) \
      || _diex 1 "couldn't hash the password"
    unset pw
    [[ $user_hash != *['"'\\]* && $user_hash != *'${'* ]] \
      || _diex 1 "hasher returned something unquotable; aborting"
    [[ $root_hash != *['"'\\]* && $root_hash != *'${'* ]] \
      || _diex 1 "hasher returned something unquotable; aborting"
  fi

  ## 5. Review
  {
    print -r -- ""
    print -r -- "Plan:"
    if (( new_host )); then
      print -r -- "  host:     $host (new, scaffolded)"
    else
      print -r -- "  host:     $host"
    fi
    (( new_host )) && {
      print -r -- "  user:     $user"
      print -r -- "  role:     $role"
      [[ $role == workstation ]] && print -r -- "  desktop:  ${desktop:-(none)}"
      print -r -- "  networks: ${networks:-(none)}"
      print -r -- "  hardware: ${hardware:-(none)}"
    }
    print -r -- "  flake:    $flake"
    print -r -- "  checkout: $src"
    if [[ -n $disko_cfg ]]; then
      if (( new_host )); then
        print -r -- "  disk:     $disk (wiped; ESP 1G + swap $swap + root)"
      else
        print -r -- "  disko:    $disko_cfg"
        [[ -n $disk ]] && print -r -- "  disk:     $disk (wiped)"
      fi
      print -r -- ""
      lsblk -o NAME,SIZE,TYPE,MOUNTPOINT 2>/dev/null || true
    else
      print -r -- "  target:   $root (already mounted)"
    fi
    print -r -- ""
  } >&2
  if (( DRY )); then
    (( new_host )) && _render_host >&2
    print -r -- "Dry run: stopping before disko/nixos-install." >&2
    return 0
  fi
  _confirm "About to install '$host'. This may wipe the target disk."

  ## 6. Scaffold files (new hosts)
  if (( new_host )); then
    mkdir -p "$hostdir/secrets"
    _render_disko > "$disko_cfg"
    _render_host > "$hostdir/default.nix"
    cp "$src/installer/secrets.nix" "$hostdir/secrets/secrets.nix"
    print -r -- "Wrote $hostdir/{default.nix,disko.nix,secrets/secrets.nix} (uncommitted)"
  elif [[ $disko_cfg == /tmp/* ]] && [[ ! -f $hostdir/disko.nix ]]; then
    _render_disko abs > "$disko_cfg"
  fi

  ## 7. Partition, then converge the staged checkout (scaffold included)
  # onto the target. Unconditional: in the disko path $flake was just
  # mounted fresh; in the manual path the stage may hold scaffold additions.
  if [[ -n $disko_cfg ]]; then
    disko --mode disko --yes-wipe-all-disks "$disko_cfg" \
      || _diex 1 "disko failed"
  fi
  mkdir -p "$flake"
  cp -a "$src/." "$flake/" || _diex 1 "couldn't lay out $flake"
  hostdir="$flake/hosts/$host"

  ## 8. Hardware config for scaffolded hosts
  if (( new_host )); then
    nixos-generate-config --root "$root" --no-filesystems \
      || _diex 1 "nixos-generate-config failed"
    cp "$root/etc/nixos/hardware-configuration.nix" \
      "$hostdir/hardware-configuration.nix" \
      || _diex 1 "couldn't copy hardware-configuration.nix"
    print -r -- "Captured $hostdir/hardware-configuration.nix"
  fi

  chown -R "${user:-root}:users" "$flake" 2>/dev/null \
    || >&2 print -r -- "Warning: couldn't chown $flake; fix it after first boot"

  ## 8b. Stage scaffolded files so flake evaluation sees them. The evaluator
  # ignores untracked files, so an un-added host is invisible to
  # nixos-install below. Staged, not committed: review, then commit. The -f
  # is for the hosts/ whitelist in .gitignore: scaffolding is an explicit
  # act, and staged hosts stay committable.
  if (( new_host )) && git -C "$flake" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -c safe.directory="$flake" -C "$flake" add -f -- "hosts/$host" \
      || _diex 1 "couldn't stage $hostdir"
    print -r -- "Staged $hostdir (still uncommitted; commit it when happy)"
  fi

  ## 9. Install
  # nixos-install doesn't have --accept-flake-config! --no-root-passwd
  # because passwords come from the host config (scaffolded hashes, or the
  # host's own settings), never from an interactive prompt mid-install.
  nixos-install --show-trace --option accept-flake-config true \
    --no-root-passwd --root "$root" --flake "$flake#$host" \
    || _diex 1 "nixos-install failed"

  print -r -- ""
  print -r -- "Installed '$host'. Next:"
  if (( new_host )); then
    print -r -- "  - review $hostdir, then commit it when happy"
    print -r -- "  - first boot, then provision the host key BEFORE adding secrets:"
    print -r -- "      hey ops push-keys $host   (from your admin machine)"
    print -r -- "    activation refuses to boot when secrets exist without their host key"
  else
    print -r -- "  - change the default (nixos) passwords if this host still sets them"
    print -r -- "  - rekey agenix secrets for this machine if it uses any"
  fi
  print -r -- "  - reboot!"
}

_render_disko() {  # [abs] -- concrete disko.nix for this install's disk
  # Scaffolded hosts get a repo-relative import (portable across checkouts);
  # the tempfile fallback gets an absolute one into staging (it lives in
  # /tmp, and $flake doesn't exist yet when disko reads it).
  if [[ ${1-} == abs ]]; then
    print -r -- "# generated by install.zsh; which disk disko formats."
    print -r -- "import \"$src/installer/disko-single.nix\" {"
  else
    print -r -- "# $host/disko.nix -- generated by install.zsh; which disk disko formats."
    print -r -- "import ../../installer/disko-single.nix {"
  fi
  print -r -- "  device = \"$disk\";"
  print -r -- "  swapSize = \"$swap\";"
  print -r -- "}"
}

_render_host() {
  # default.nix pinning installer/host-template.nix. Every value below is
  # validated above (names, lists) or hasher-generated (hashes), so plain
  # interpolation is safe.
  local dt="$desktop" nets hw
  [[ $role == workstation ]] || dt=""
  nets=$(_quote_list "$networks")
  hw=$(_quote_list "$hardware")
  print -r -- "# $host -- scaffolded by install.zsh; uncommitted until you say so."
  print -r -- "#"
  print -r -- "# Pins installer/host-template.nix with this machine's answers. Edit"
  print -r -- "# freely; re-run install.zsh (or \`hey sync\`) to apply."
  print -r -- ""
  print -r -- "{ self, lib, ... }:"
  print -r -- ""
  print -r -- "import ../../installer/host-template.nix {"
  print -r -- "  inherit self lib;"
  print -r -- "  hostName = \"$host\";"
  print -r -- "  user = \"$user\";"
  print -r -- "  role = \"$role\";"
  if [[ -n $dt ]]; then
    print -r -- "  desktop = \"$dt\";"
  else
    print -r -- "  desktop = null;"
  fi
  print -r -- "  networks = [ $nets ];"
  print -r -- "  hardware = [ $hw ];"
  print -r -- "  diskoConfig = ./disko.nix;"
  print -r -- "  hardwareConfig = ./hardware-configuration.nix;"
  print -r -- "  userPasswordHash = \"$user_hash\";"
  print -r -- "  rootPasswordHash = \"$root_hash\";"
  print -r -- "}"
}

set -e
main "$@"
