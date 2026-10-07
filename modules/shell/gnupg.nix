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
  cfg = config.modules.shell.gnupg;
in {
  options.modules.shell.gnupg = with types; {
    enable = mkBoolOpt false;
    cacheTTL = mkOpt int 3600; # 1hr

    # The pinentry the agent spawns. Absolute: the agent doesn't see the
    # session's PATH. Defaults to the curses prompt, so passphrases are asked
    # for in the terminal the command was run from.
    pinentry = mkOpt' (nullOr str) null "The pinentry program gpg-agent spawns (default: pinentry-curses).";
  };

  config = mkIf cfg.enable {
    environment.sessionVariables.GNUPGHOME = "$HOME/.config/gnupg";

    # systemd.user.services.gpg-agent.serviceConfig.Environment = [
    #   "GNUPGHOME=${config.home.configDir}/gnupg"
    # ];

    programs.gnupg.agent.enable = true;

    # GNUPGHOME is ~/.config/gnupg, so this is the conf the agent reads. It has
    # to name the pinentry itself: programs.gnupg.agent.pinentryPackage writes
    # its own conf, which this explicit file replaces, leaving the agent with
    # no pinentry at all.
    home.configFile."gnupg/gpg-agent.conf".text = ''
      pinentry-program ${
        if cfg.pinentry != null
        then cfg.pinentry
        else getExe pkgs.pinentry-curses
      }
      default-cache-ttl ${toString cfg.cacheTTL}
      allow-emacs-pinentry
      allow-loopback-pinentry
    '';
  };
}
