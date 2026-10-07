#!/usr/bin/env zsh
# Record a region of the screen to clipboard.
#
# SYNOPSIS:
#   screencast [webm|mp4|gif] [TARGET] [DELAY]
#
# DESCRIPTION:
#   Prompts the user to select a region, window, or monitor to begin recording
#   with wf-recorder. Produces a webm by default, but can also produce mp4' or
#   gifs.
#
# DEPENDENCIES:
#   wf-recorder, ffmpeg, gifsicle**
#
#   ** Is auto-installed by cached-nix-shell if needed.
#
# ARGUMENTS:
#   1 FORMAT
#     webm      -- Optimized for short recordings of text or code (the default).
#     mp4       -- Optimized for high-motion content.
#     gif       -- Produce an animated gif.
#   2 TARGET
#     last      -- Reuse the previous selection.
#     region    -- Select an arbitrary region (the default).
#     window    -- Select a window.
#     output    -- Select a monitor.
#   3 DELAY

_cleanup() {
  rm -f "$livefile"
  return 0
}

main() {
  magi.requires wf-recorder ffmpeg

  local file
  local -a opts=( --audio-backend pipewire )
  if [[ -f "$livefile" ]]; then
    pkill -SIGINT wf-recorder
    rm -f "$livefile"
    return
  fi
  case "${1:-webm}" in
    webm)
      file="$prefix.webm"
      # Optimized for short (sub-30s) recordings of text/code. Use mp4 for
      # gaming-quality recordings.
      opts+=( \
        -c libvpx-vp9 -x yuv444p -r 30 \
        -p crf=24 -p cpu-used=0 -p deadline=good \
        -p row-mt=1 -p tile-columns=2 -p b=0 -p g=240 \
      )
      ;;
    mp4)
      file="$prefix.mp4"
      # Optimized for high-motion (sub-30s) recordings of high-motion content,
      # like games or video.
      opts+=( \
        --audio -c libx264 -r 60 -B 60 -b 5 \
        -p preset=slow -p tune=animation -p crf=18 \
        -p g=300 -p keyint_min=60 -p aq-mode=3 \
        -p profile=high -p level=4.2 \
      )
      ;;
    gif)
      file="$prefix.gif"
      # Not optimized at all. There really is little reason to use gif over
      # webm, but I keep it here for posterity. Ideally, it should be encoded to
      # some other raw format and post-processed to gif with ffmpeg, but I can't
      # be assed to do that here, since I never use this.
      opts+=( --codec gif )
      ;;
    *) magi.abort "Unknown format: $1" ;;
  esac
  rm -f "$file"
  touch "$livefile"
  trap _cleanup EXIT SIGINT SIGTERM
  local geom="$(magi .slurp ${2:-region})"
  [[ -z "$geom" ]] && exit 1
  # slurp prints "X,Y WxH"; validating it is also how we take it apart.
  [[ "$geom" =~ '^(-?[0-9]+),(-?[0-9]+) ([0-9]+)x([0-9]+)$' ]] \
    || magi.abort "Unrecognized geometry: $geom"

  local delay="$3"
  if [[ -n "$delay" ]] && (( delay > 0 )); then
    for i in {$delay..1}; do
      magi wm play-sound blip &
      magi.toast -c countdown warn "Recording starting in... $i"
      sleep 1
    done
  fi
  # Marks the recording as live for this script's own toggle.
  print -r -- $EPOCHSECONDS >| $livefile
  wf-recorder -g "$geom" ${opts[@]} --file="$file"
  local rc=$?
  if (( rc == 0 )); then
    sleep 0.1
    if [[ $1 == gif ]]; then
      magi.toast warn "Optimizing gif. This may take a while..."
      magi.do -! gifsicle --optimize=3 "$file"
    fi
    echo "file://$file" | wl-copy -t text/uri-list
    magi wm play-sound success &
    magi.toast info "Recording complete. Copied to clipboard!"
  fi
}

zmodload zsh/datetime  # EPOCHSECONDS

typeset -g prefix=$(magi path runtime screencast)
typeset -g livefile=$prefix.live
main $@
