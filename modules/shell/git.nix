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
  cfg = config.modules.shell.git;
in {
  options.modules.shell.git = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      diff-so-fancy
      gh
      git-annex
      git-open
      (mkIf config.modules.shell.gnupg.enable git-crypt)
      act
    ];

    home.configLink = {
      "git/config" = "${config.magi.configDir}/git/config";
      "git/ignore" = "${config.magi.configDir}/git/ignore";
      "git/attributes" = "${config.magi.configDir}/git/attributes";
    };

    modules.shell.zsh.rcFiles = ["${config.magi.configDir}/git/aliases.zsh"];
  };
}
