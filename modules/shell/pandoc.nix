# modules/shell/pandoc.nix --- for document conversion
#
# pandoc plus a TeXLive set, for markdown-to-PDF via
# config/pandoc/md2pdf_filter.lua (from Bekaboo/dot's .pandoc). Also the
# backend behind config/claude/scripts' html2md reference pipeline.
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
  cfg = config.modules.shell.pandoc;
in {
  options.modules.shell.pandoc = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      pandoc
      texlive.combined.scheme-small
    ];

    # Pandoc's user data dir is $XDG_DATA_HOME/pandoc (legacy ~/.pandoc).
    home.dataLink."pandoc" = "${config.hey.configDir}/pandoc";
  };
}
