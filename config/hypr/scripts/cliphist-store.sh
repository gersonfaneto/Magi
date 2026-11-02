#!/bin/sh
# Skip sensitive clipboard data (CLIPBOARD_STATE=sensitive) so passwords copied
# with wl-copy --sensitive never reach the persistent cliphist database.
case "$CLIPBOARD_STATE" in
  data) cliphist store ;;
  *) cat >/dev/null ;;
esac
