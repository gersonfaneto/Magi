## modules/shell/ranger.nix
#
# ranger, console file manager with vim-like bindings and fzf integration,
# from Bekaboo/dot (.config/ranger).
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
  cfg = config.modules.shell.ranger;
in {
  options.modules.shell.ranger = with types; {
    enable = mkBoolOpt false;
    extraPackages =
      mkOpt' (listOf package) []
      "Extra binaries to put on ranger's PATH, for previewers and openers.";
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs;
      [
        ranger
        file # scope.sh file identification
        bat # scope.sh syntax-highlighted previews
        highlight # scope.sh fallback highlighter
        atool # scope.sh archive listing
        w3m # scope.sh html preview
      ]
      ++ cfg.extraPackages;

    home.configLink."ranger" = "${config.magi.configDir}/ranger";
    modules.shell.zsh.rcFiles = ["${config.magi.configDir}/ranger/aliases.zsh"];
  };
}
