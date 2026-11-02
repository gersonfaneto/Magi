#!/usr/bin/env janet
# Reload running services.
#
# SYNOPSIS:
#   reload [@AREA]
#
# DESCRIPTION:
#   Triggers the on-reload hook, which restarts or reloads whatever the active
#   host and window manager have registered for it. Given an AREA, only that
#   area's handler is triggered (see magi hook).
#
# ARGUMENTS:
#   1 AREA @hook-areas

(use magi)
(import magi/sys)

(defcmd reload [_ area]
  (def area (if (and area (not (string/has-prefix? "@" area)))
              (string "@" area)
              area))
  # magi.desktop, not XDG_CURRENT_DESKTOP: a tty has the latter unset, and this
  # is only a label, so it shouldn't be the thing that says "nil".
  (echof :g "Reloading %s..."
         (or area (ignore-errors (flake/info :desktop)) "everything"))
  (when (magi! hook ,;(opts area) on-reload -f -v)
    (sys/toast :info "Finished reloading system"
               :icon "refresh-alert"
               :sound 'notify))
  (echo :check "Done!"))
