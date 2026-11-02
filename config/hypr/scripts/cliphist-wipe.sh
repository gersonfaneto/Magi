#!/bin/sh
# Start every session with an empty clipboard history. Cached image thumbnails
# are named after the entries, so they have to go with them.
cliphist wipe
rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/cliphist-thumbs"
