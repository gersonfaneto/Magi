#!/usr/bin/env zsh
# Converts high-quality FLAC files down to 16bit/44.1kHz.
#
# SYNOPSIS:
#   hey .flac down *.flac

main() {
  local file="$1"
  local bps=$(metaflac --show-bps "$file")
  local rate=$(metaflac --show-sample-rate "$file")

  if (( bps == 16 && rate == 44100 )); then
    >&2 echo "$file already at 16/44. Aborting..."
    return 1
  fi

  local destfile="${file%.flac}"
  if [[ $destfile == *" [$bps-$(( rate / 1000 ))]" ]]; then
    destfile="${destfile% \[*\]}"
  fi
  destfile="${destfile} [16-44].flac"

  ffmpeg -i "$file" \
    -y -vn \
    -af "aresample=resampler=soxr:dither_method=triangular" \
    -ar 44100 -sample_fmt s16 \
    -c:a flac \
    "$destfile"
}

for f in "$@"; do main "$f"; done
