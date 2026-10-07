#!/usr/bin/env janet
# Ask SYSTEM about itself.
#
# SYNOPSIS:
#   magi ops info SYSTEM [ARGS...]
#
# DESCRIPTION:
#   `magi info`, run over there. ARGS go to it verbatim, so every flag and key
#   magi info takes works here: `magi ops info soba profiles role -r`.
#
# ARGUMENTS:
#   1 SYSTEM @hosts
#   ** ARGS

(use magi)
(import magi/ops)

# Raw arguments, so magi info's own -r and -w survive the trip.
(defcmd info [_ & _ argv]
  (def [system & args] (slice argv 1))
  (unless system (usage))
  (ops/check system)
  (exit (os/execute
         ["ssh" system
          (string/join ["magi" "info" ;(map shell-quote args)] " ")]
         :p)))
