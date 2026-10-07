## modules/shell/search.nix
#
# Shared finder config: fd ignore rules and ripgrep defaults, from Bekaboo/dot
# (.config/fd/ignore, .ripgreprc). fd and ripgrep themselves ride along with
# the editors and zsh modules; this module owns their config files, so a host
# gets consistent `fd`/`rg` behavior (including inside yazi/ranger/fzf) by
# flipping one switch.
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
  cfg = config.modules.shell.search;
in {
  options.modules.shell.search = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      fd
      ripgrep
    ];

    home.configLink = {
      "fd/ignore" = "${config.hey.configDir}/fd/ignore";
      "ripgrep/ripgreprc" = "${config.hey.configDir}/ripgrep/ripgreprc";
    };

    # Upstream exports this from ~/.profile; the session variable is the
    # XDG-respecting equivalent.
    environment.sessionVariables.RIPGREP_CONFIG_PATH = "${config.home.configDir}/ripgrep/ripgreprc";
  };
}
