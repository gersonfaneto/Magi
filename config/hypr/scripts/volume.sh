#!/bin/sh
# Raise the default output by 5%, capped at 100%.
exec wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+
