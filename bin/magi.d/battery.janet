#!/usr/bin/env janet
# Monitor the laptop battery and manage low-battery policy.
#
# SYNOPSIS:
#   battery status [--json]
#   battery watch [--once] [--interval SECONDS]
#
# OPTIONS:
#   --json
#     Emit status as JSON instead of a human-readable line.
#   --once
#     Take a single sample and exit, instead of watching continuously.
#   --interval SECONDS
#     Poll every SECONDS instead of the configured default.
#
# ARGUMENTS:
#   1 COMMAND
#     status -- Print the current battery percentage and charge state.
#     watch  -- Run the warning and low-battery policy as a daemon.

(use magi)
(import magi/battery)

(defcmd battery [_ cmd & args &opts json? --json once? --once interval [--interval interval]]
  (case cmd
    nil (usage)
    "status" (battery/status json?)
    "watch" (battery/watch :once? once?
                           :interval (when interval (scan-number interval)))
    (usage)))
