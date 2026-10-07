#!/usr/bin/env janet
# A script exercising the whole completion-spec grammar.
#
# SYNOPSIS:
#   specs [-a] [-l|--list] [-e|-f|-d] [--host HOST] [COMMAND] [ARGS...]
#
# OPTIONS:
#   -a
#     A plain flag, with a bracket ] and a back\slash.
#   -l, --list
#     Two spellings of one option.
#   -e | -f | -d
#     Three mutually exclusive options.
#   --host HOST @hosts
#     An option taking a value, completed by a function.
#   TODO
#
# ARGUMENTS:
#   1 COMMAND
#     one     -- A description with "quotes", $DOLLAR and a `backtick`.
#     wm*     Column-aligned, and a value needing escapes.
#   2 PLAIN
#   * REST @sync-arg
