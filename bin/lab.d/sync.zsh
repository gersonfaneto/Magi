#!/usr/bin/env zsh
#
# Backup all personal files to several locations.
#
# I switch between workstations for different workloads. Timing issues and diff
# conflicts make automated solutions (like syncthing or rclone/rsyncing on a
# cronjob) unreliable and opaque, so I opt for a script to manually sync them on
# demand, which seconds as a backup script (to my NAS).
#
# SYNOPSIS:
#   $0

function rcp {
  echo
  magi.echo -c green "# Pushing $1 to $2"
  magi.do rsync -azPJ \
    --include=.git/ \
    --filter=':- .gitignore' \
    --filter=":- $XDG_CONFIG_HOME/git/ignore" \
    "$@"
}

function rcpd {
  rcp "$@" --delete --delete-during
}

function available-host {
  nc -w 2 -z "$1" 22 2>/dev/null
}


if [[ "$(whoami)" != hlissner ]]; then
  magi.error "Must be hlissner!"
  exit 1
fi

set -e
local host=$(hostname)
case $host in
  udon)
    magi.do rcpd ~/projects/ /media/backup/nas0/hlissner/projects/

    if available-host ramen.lan; then
      magi.do rcpd ~/projects/ ramen.lan:~/projects/
    else
      magi.error "Couldn't connect to ramen.lan"
    fi

    if available-host nas0.lan; then
      magi.do rcpd ~/projects/ nas0.lan:~/files/projects/
      # Update local backups
      magi.do rcpd nas0.lan:/mnt/nas/backup/files/ /media/backup/nas0/apps/
      magi.do rcpd nas0.lan:~/files/ /media/backup/nas0/hlissner/
    else
      magi.error "Couldn't connect to nas0.lan"
    fi

    if available-host soba.lan; then
      if ssh soba.lan test -s ~/Media/external; then
        magi.do rcpd /media/backup/nas0/hlissner/ soba.lan:~/Media/external
      fi
    else
      magi.error "Couldn't connect to soba.lan"
    fi
    ;;

  ramen)
    if ! available-host udon.lan; then
      magi.error "Can't connect to udon.lan"
      exit 1
    fi
    magi.do rcpd ~/projects/ udon.lan:~/projects/

    if available-host nas0.lan; then
      magi.do rcpd ~/projects/ nas0.lan:~/files/projects/
    else
      magi.error "Couldn't connect to nas0.lan"
    fi
    ;;

  soba)
    if available-host nas0.lan; then
      if [[ -f ~/Media/backup0/.backup ]]; then
        magi.do rcpd nas0.lan:~/files/ ~/Media/backup0/
        if [[ -f ~/Media/backup1/.backup ]]; then
          magi.do rcpd ~/Media/backup0/ ~/Media/backup1/
        fi
      fi
    else
      magi.error "Couldn't connect to nas0.lan"
    fi
    ;;

  htpc)
    if available-host nas0.lan; then
      for category in audiobooks books anime documentaries movies tv; do
        rcp "root@nas0.lan:/mnt/nas/media/$category/" "$HOME/jellyfin/$category/"
      done
      ssh root@nas0.lan "rsync -azPJ /mnt/nas/media/music/ /mnt/nas/users/hlissner/files/music/unsorted/"
    else
      magi.error "Couldn't connect to nas0.lan"
    fi
    ;;

  *)
    magi.error "Unknown host: $host"
    exit 1
    ;;
esac

magi.echo -c green "✓ Done"
