#!/usr/bin/env zsh
# Splits up a flac file into multiple from a *.cue file.
#
# SYNOPSIS:
#   hey .flac split *.cue *.flac

main() {
  shnsplit -f "$1" -o flac "$2"
  [[ -f split-track00.flac ]] && rm -f split-track00.flac
  cuetag.sh "$1" split-track*.flac

  local totaldiscs=$(metaflac --show-tag=TOTALDISCS split-track01.flac | sed 's/.*=//')
  for f in split-track*.flac; do
    local track=$(metaflac --show-tag=TRACKNUMBER "$f" | sed 's/.*=//')
    local title=$(metaflac --show-tag=TITLE "$f" | sed 's/.*=//')
    local bitdepth=$(metaflac --show-bps "$f")
    local bitrate=$(metaflac --show-sample-rate "$f")
    local quality=$(printf "[%d-%d]" "$bitdepth" "$(( bitrate / 1000 ))")
    if (( totaldiscs > 1 )); then
      local disc=$(metaflac --show-tag=DISCNUMBER "$f" | sed 's/.*=//')
      track=$(printf "%d-%02d" "$disc" "$track")
    else
      track=$(printf "%02d" "$track")
    fi
    mv -v -- "$f" "$track ${title//\//-} $quality.flac"
  done
}

set -e
main "$1" "$2"
