#!/usr/bin/env zsh
# Rename files to YYYYMMDD-<md5>.ext
#
# SYNOPSIS:
#   hashify [FILE|DIR]...
#
# DESCRIPTION:
#   YYYYMMDD are derived from a file's creation date. Useful for archiving large
#   swathes of downloaded media (mostly memes, images, or documents). I use
#   other tools to organize these files so the filename just needs to be
#   sufficiently unique and indicate the date the file was added.
#
# EXAMPLES:
#   magi .hashify ~/Pictures/wallpapers
#   MAGIDRYRUN=1 magi .hashify
#
# ARGUMENTS:
#   * FILE @files

setopt extendedglob
zmodload zsh/datetime

local -a files
for p in ${@:-.}; do
  [[ -d $p ]] && files+=( $p/*(.N) ) || files+=( $p )
done

for f in $files; do
  b=${f:t}
  [[ $b == [0-9](#c8)-[0-9a-f](#c32)(|.*) ]] && continue
  e=${b:e}
  if [[ ${b:r} == (#b)*([0-9a-fA-F](#c32))* ]]; then
    h=${match[1]:l}
  else
    h=${${(z)$(md5sum -- $f)}[1]}
  fi
  t=$(stat -c %W -- $f); (( t > 0 )) || t=$(stat -c %Y -- $f)
  n=${f:h}/$(strftime %Y%m%d $t)-$h${e:+.${e:l}}
  [[ -e $n ]] && { magi.warn "skip $f: $n exists"; continue }
  magi.do mv -n -- $f $n
done
