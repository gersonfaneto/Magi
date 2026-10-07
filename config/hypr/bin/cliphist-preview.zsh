#!/usr/bin/env zsh
# Render one cliphist entry for fsel's preview panel.
#
# Rows are cliphist's `ID<TAB>content` lines. fsel turns the decoded bytes into
# an inline image or text on its own.
#
# SYNOPSIS:
#   cliphist-preview ROW

emulate -L zsh
local row=$1
[[ -n $row ]] || exit 1

local id=${row%%$'\t'*}
[[ -n $id ]] || exit 1

cliphist decode "$id"
