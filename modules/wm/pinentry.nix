# modules/wm/pinentry.nix
#
# The passphrase card: a Quickshell surface (config/pinentry/) that answers
# gpg-agent's pinentry protocol, `sudo -A` and ssh's askpass, so every secret
# prompt looks like the rest of the shell instead of a stock Qt dialog.
#
# Off by default; it rides on modules.wm.quickshell, and hosts just set
# modules.wm.quickshell.enable like they do for the pill and the lock.
#
# The shim (config/pinentry/bin/pinentry.py) is the only thing that speaks
# pinentry; the surface is a plain Unix-socket peer, and both sides fall back
# to the terminal when the shell isn't around, so a TTY login, a broken
# session or a dead surface never traps the user out of gpg, ssh or sudo.
{
  self,
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with self.lib; let
  cfg = config.modules.wm;
  qcfg = cfg.quickshell;
  pcfg = cfg.pinentry;

  shim = "${config.magi.configDir}/pinentry/bin/pinentry.py";
  python = getExe' pkgs.python3 "python3";

  # gpg-agent takes a bare program path, and so do SUDO_ASKPASS/SSH_ASKPASS, so
  # the two entry points are separate launchers around the same script.
  protocol = pkgs.writeShellScript "pinentry-quickshell" ''
    exec ${python} ${shim} "$@"
  '';
  askpass = pkgs.writeShellScript "pinentry-quickshell-askpass" ''
    exec ${python} ${shim} --askpass "$@"
  '';
  askpassPath = "${config.home.dir}/.local/bin/pinentry-quickshell-askpass";
in {
  options.modules.wm.pinentry = with types; {
    enable = mkOpt' bool qcfg.enable "Answer passphrase prompts in the Quickshell pinentry card.";
  };

  config = mkIf (cfg.desktop == "hyprland" && qcfg.enable && pcfg.enable) {
    home.file = {
      ".local/bin/pinentry-quickshell" = {
        source = protocol;
        executable = true;
      };
      ".local/bin/pinentry-quickshell-askpass" = {
        source = askpass;
        executable = true;
      };
    };

    # The card listens on $XDG_RUNTIME_DIR/quickshell-pinentry.sock; pinning the
    # variable on the unit keeps it the same hub the shim guesses. The unit is
    # not started at login: the shim starts it on the first prompt and the
    # surface quits after ten idle minutes, so an unused card costs no RAM.
    systemd.user.services.quickshell-pinentry = {
      description = "Quickshell pinentry (passphrase card)";
      partOf = ["graphical-session.target"];
      after = [
        "graphical-session.target"
        "wayland-wm@hyprland.desktop.service"
      ];
      # Like the greeter, the card is a bare -p path into the live checkout, so
      # a QML edit is picked up by Quickshell's file watch, not a rebuild.
      enableDefaultPath = false;
      serviceConfig = {
        ExecStart = "${getExe' qcfg.package "qs"} -p ${config.magi.configDir}/pinentry/surface";
        Environment = "XDG_RUNTIME_DIR=%t";
        Restart = "on-failure";
        RestartSec = 1;
      };
    };

    # gpg-agent spawns the shim instead of pinentry-qt. Absolute, since the
    # agent runs with systemd's environment, not the login shell's.
    modules.shell.gnupg.pinentry = mkDefault "${config.home.dir}/.local/bin/pinentry-quickshell";

    # sudo and ssh only consult askpass when there's no terminal, so point them
    # at the card and let ssh ask it even from a TTY (SSH_ASKPASS_REQUIRE).
    # sudo needs `-A` or `Defaults askpass`; aliases.zsh adds the flag to the
    # interactive `sudo`, leaving scripts on the terminal prompt. ssh owns its
    # variable through programs.ssh, which nixpkgs otherwise points at
    # x11-ssh-askpass (or leaves empty outside X).
    programs.ssh = {
      enableAskPassword = true;
      askPassword = askpassPath;
    };
    environment.sessionVariables = {
      SUDO_ASKPASS = "$HOME/.local/bin/pinentry-quickshell-askpass";
      SSH_ASKPASS_REQUIRE = "force";
    };
  };
}
