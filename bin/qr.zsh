#!/usr/bin/env zsh
# Create a QR code from FILE or stdin.
#
# SYNOPSIS:
#   magi .qr FILE
#   echo TEXT | magi .qr

cat $@ | magi.do -! -p qrencode qrencode -t ansiutf8
