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
    # no pinentry at all. pinentry-qt matches the session's Qt theming.
    home.configFile."gnupg/gpg-agent.conf".text = ''
      pinentry-program ${pkgs.pinentry-qt}/bin/pinentry-qt
      default-cache-ttl ${toString cfg.cacheTTL}
      allow-emacs-pinentry
      allow-loopback-pinentry
    '';
  };
}
