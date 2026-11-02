# test/nixos/modules/wm/pinentry.nix --- tests for modules/wm/pinentry.nix
#
# The module is what makes the card reachable: the surface unit, the two shim
# launchers, gpg-agent's pinentry-program and the askpass variables. The shim
# itself is exercised by test/pinentry; this suite only checks the wiring, so a
# broken path here fails the build instead of silently leaving pinentry-qt.
{
  evalConfig,
  lib,
  ...
}:
with lib; let
  on = evalConfig [
    {
      modules.wm.desktop = "hyprland";
      modules.wm.quickshell.enable = true;
      modules.shell.gnupg.enable = true;
    }
  ];
  off = evalConfig [
    {
      modules.wm.desktop = "hyprland";
      modules.wm.quickshell.enable = true;
      modules.wm.pinentry.enable = false;
      modules.shell.gnupg.enable = true;
    }
  ];
  noShell = evalConfig [{modules.wm.desktop = "hyprland";}];

  unit = on.systemd.user.services.quickshell-pinentry;
  shim = "${on.home.dir}/.local/bin/pinentry-quickshell";
  askpass = "${on.home.dir}/.local/bin/pinentry-quickshell-askpass";
in {
  ## Gating.

  # Off unless asked (or unless the shell is on), so nothing double-starts and
  # a non-Quickshell desktop keeps pinentry-qt.
  testOffByDefaultStartsNothing = {
    expr = {
      noService = off.systemd.user.services ? quickshell-pinentry;
      noShim = off.home.link ? "${off.home.dir}/.local/bin/pinentry-quickshell";
      noAskpass = off.environment.sessionVariables ? SUDO_ASKPASS;
      noPinentry = off.modules.shell.gnupg.pinentry;
      withoutShell = noShell.systemd.user.services ? quickshell-pinentry;
    };
    expected = {
      noService = false;
      noShim = false;
      noAskpass = false;
      noPinentry = null;
      withoutShell = false;
    };
  };

  ## The surface.

  # A -p path, so the card is the live checkout rather than a snapshot: a QML
  # edit only needs the service to reload it. It is started on demand by the
  # shim, so it must not be wanted by the session target.
  testRunsTheCardFromTheCheckout = {
    expr = {
      path = hasInfix "-p /etc/magi/config/pinentry/surface" unit.serviceConfig.ExecStart;
      qs = hasInfix "/bin/qs" unit.serviceConfig.ExecStart;
      restart = unit.serviceConfig.Restart;
      sessionPath = unit.enableDefaultPath;
      wanted = unit.wantedBy or [];
    };
    expected = {
      path = true;
      qs = true;
      restart = "on-failure";
      sessionPath = false;
      wanted = [];
    };
  };

  # The surface and the shim have to agree on one hub, so the unit pins the
  # runtime dir itself instead of trusting the service environment.
  testPinsTheRuntimeDir = {
    expr = unit.serviceConfig.Environment;
    expected = "XDG_RUNTIME_DIR=%t";
  };

  # A switch must not start the card either: the shim does it on the first
  # prompt, and a stale activation script would leave an idle Qt process around.
  testSwitchDoesNotStartTheSurface = {
    expr = on.system.userActivationScripts ? magi-start-pinentry;
    expected = false;
  };

  ## The launchers.

  # gpg-agent and SUDO_ASKPASS/SSH_ASKPASS each need a bare program path.
  testLinksBothLaunchers = {
    expr = {
      protocol = hasPrefix "/nix/store/" on.home.link."${on.home.dir}/.local/bin/pinentry-quickshell";
      askpass = hasPrefix "/nix/store/" on.home.link."${on.home.dir}/.local/bin/pinentry-quickshell-askpass";
    };
    expected = {
      protocol = true;
      askpass = true;
    };
  };

  ## gpg-agent.

  testGpgSpawnsTheShim = {
    expr = {
      option = on.modules.shell.gnupg.pinentry;
      conf = hasInfix "pinentry-program ${shim}" on.home.configFile."gnupg/gpg-agent.conf".text;
    };
    expected = {
      option = shim;
      conf = true;
    };
  };

  # Without the card, gpg keeps its own pinentry instead of having none.
  testFallsBackToPinentryQt = {
    expr = {
      option = off.modules.shell.gnupg.pinentry;
      qt = hasInfix "pinentry-program /nix/store/" off.home.configFile."gnupg/gpg-agent.conf".text;
      name = hasInfix "pinentry-qt" off.home.configFile."gnupg/gpg-agent.conf".text;
    };
    expected = {
      option = null;
      qt = true;
      name = true;
    };
  };

  # A host can still name its own pinentry; the card is only a default.
  testAnExplicitPinentryWins = {
    expr = hasInfix "pinentry-program /run/other/pinentry\n" (
      (evalConfig [
        {
          modules.wm.desktop = "hyprland";
          modules.wm.quickshell.enable = true;
          modules.shell.gnupg.enable = true;
          modules.shell.gnupg.pinentry = "/run/other/pinentry";
        }
      ])
      .home
      .configFile
      ."gnupg/gpg-agent.conf"
      .text
    );
    expected = true;
  };

  ## sudo and ssh.

  # Relative to $HOME like the other session variables, so it isn't pinned to
  # one user's home directory; ssh is forced to ask even from a terminal, and
  # borrows the card through programs.ssh (nixpkgs would point it at
  # x11-ssh-askpass, or nothing outside X).
  testPointsAskpassAtTheCard = {
    expr = {
      sudo = on.environment.sessionVariables.SUDO_ASKPASS;
      force = on.environment.sessionVariables.SSH_ASKPASS_REQUIRE;
      ssh = on.environment.variables.SSH_ASKPASS;
      sshProgram = on.programs.ssh.askPassword;
    };
    expected = {
      sudo = "$HOME/.local/bin/pinentry-quickshell-askpass";
      force = "force";
      ssh = askpass;
      sshProgram = askpass;
    };
  };

  # rbw refuses to borrow the agent's pinentry, so it has to be handed the same
  # shim (it speaks the same protocol).
  testVaultwardenBorrowsTheShim = {
    expr =
      (evalConfig [
        {
          modules.wm.desktop = "hyprland";
          modules.wm.quickshell.enable = true;
          modules.shell.gnupg.enable = true;
          modules.shell.vaultwarden.enable = true;
        }
      ])
      .modules
      .shell
      .vaultwarden
      .settings
      .pinentry;
    expected = shim;
  };
}
