## modules/shell/scripts.nix
#
# My personal bin scripts, ported from Bekaboo/dot's .bin. They live in the
# live checkout (config/bin) and are symlinked into $XDG_BIN_HOME
# (~/.local/bin), which modules/home.nix puts on PATH via localBinInPath, so an
# edit takes effect without a rebuild. The md2* frontends ride on
# modules.shell.pandoc's data dir ($XDG_DATA_HOME/pandoc).
#
# setcolor/setbg (with their getbg/suggestbg/checkbg/syncbg helpers) are thin
# frontends to `magi theme`, which owns the static theme sets in
# config/{foot,highlight}/themes and renders the active one for every app.
{
  self,
  lib,
  config,
  options,
  pkgs,
  ...
}:
with lib;
with self.lib; let
  cfg = config.modules.shell.scripts;

  scripts = [
    "checkbg" # set the bg to the suggested one
    "cht" # query cheat.sh (vendored cht.sh client)
    "cursorpos" # get the terminal cursor position
    "ex" # extract archives, wisely
    "ff" # fuzzy-open files from a base dir
    "fo" # fuzzy-open a file from nvim's v:oldfiles
    "fugitive" # open files in vim-fugitive
    "fugitive-gbrowse" # the gb alias, browsing a commit in the browser
    "gb"
    "getbg" # print the system bg (light/dark)
    "gr" # find a regex pattern using rg + fzf
    "gx" # open files with $EDITOR or xdg-open
    "fzf-file-previewer" # fzf --preview helper
    "fzf-wrapper"
    "hex2rgb"
    "imu" # imagemagick one-liners (convert, borders, flips, bg removal)
    "jif" # video -> optimized gif via ffmpeg
    "mb" # make (or restore) a <file>.bak backup
    "md2html" # markdown -> standalone html
    "md2html2pdf" # markdown -> pdf via wkhtmltopdf
    "md2pdf" # markdown -> pdf via LaTeX
    "md2tex" # markdown -> tex
    "nvim-restore" # reopen the workspace session autosaved for the cwd
    "nvim-socks" # list/expose nvim server sockets
    "pdftools" # merge/split/extract/convert PDFs with ghostscript
    "room" # open a shell in a temporary directory
    "run" # compile-and-run a C/C++ file
    "serve" # serve a directory over HTTP
    "setbg" # set the light/dark tone for the whole desktop
    "setcolor" # set the colorscheme for the whole desktop
    "showcolors" # print the terminal's 16 colors
    "suggestbg" # print the bg suggested by sunrise/sunset (or the clock)
    "syncbg" # sync apps' bg with the system bg
    "testcolors"
    "tmx" # interactive tmux session switcher
    "trans" # translate text via an OpenAI-compatible API
    "usb-reset-all" # reset the USB controllers
    "whereami" # current location as 'latitude longitude'
    "wtf" # check (or kill) the process on a TCP port
    "ytdl" # download audio from YouTube with yt-dlp
  ];
in {
  options.modules.shell.scripts = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    # The finder stack the fzf/fugitive scripts lean on; the rest of their
    # tools (nvim, pandoc, gcc, imagemagick, ffmpeg, ghostscript, yt-dlp, tmux,
    # lsof, notify-send, wl-clipboard, python3) ride on the modules that install
    # them. `perl`, `curl` and `rlwrap` (cht's shell mode) are not guaranteed
    # elsewhere.
    user.packages = with pkgs; [
      bat
      curl
      fd
      fzf
      highlight
      jq
      perl
      ripgrep
      rlwrap
      tree
      unzip
      w3m
    ];

    home.link = listToAttrs (
      map (name: nameValuePair ".local/bin/${name}" "${config.magi.configDir}/bin/${name}") scripts
    );

    # setcolor/setbg used to drop dark.theme/light.theme/highlight.theme
    # symlinks here. theme.py now renders highlight.theme from the active bundle
    # into the same directory, so the fzf previewer's --config-file keeps
    # working without writing into the checkout.
    home.file.".highlight/themes" = {
      source = "${self.configDir}/highlight/themes";
      recursive = true;
    };

    modules.wm.theme.files.highlight = {
      input_path = "${config.magi.configDir}/theme/highlight.template.theme";
      output_path = "${config.home.dir}/.highlight/themes/highlight.theme";
    };
  };
}
