#!/usr/bin/env janet
# Open a Janet REPL with magi's library loaded, or inside a script.
#
# SYNOPSIS:
#   repl [FILE]
#
# DESCRIPTION:
#   Without FILE, the REPL starts with magi, magi/vars, magi/glob and magi/sys
#   loaded. With it, FILE is evaluated and the REPL starts inside its
#   environment, private bindings and all. Its main isn't called, but the rest
#   of its top level runs, so a script that does its work there does it now.
#
#   For a Nix repl in this flake, use `nix develop`.
#
# ARGUMENTS:
#   1 FILE @files

(use magi)
(use sh)

(defcmd repl [_ file]
  (if file
    (do (unless (path/file? file)
          (abort "No such file: %s" file))
        (echof :g "Starting Janet REPL (inside %s)..." (path/abbrev file))
        # Avoiding -l b/c import only hands over public bindings
        (do? $ janet -e ,(string/format "(repl nil nil (dofile %j))" file)))
    (do (echo :g "Starting Janet REPL (w/ MagiLib preloaded)...")
        (do? $ janet
             -l magi
             -e "(import magi/vars)"
             -e "(import magi/glob)"
             -e "(import magi/sys)"
             -p -r))))
