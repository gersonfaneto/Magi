# test/nixos/modules/flatpak.nix --- tests for modules/apps/flatpak.nix
#
# The ensure unit and the on-gc hook are the only things that install or
# remove a flatpak, and both fail quietly: a unit that never runs looks the
# same as one with nothing to do, and a hook no host enables is just a file.
# Pin the wiring so neither can fall off.
{
  evalConfig,
  lib,
  ...
}:
with lib; let
  on = evalConfig [{modules.apps.flatpak.enable = true;}];
  off = evalConfig [];
  service = on.systemd.services.magi-flatpak-ensure-packages;
  hook = on.home.dataFile."magi/hooks.d/flatpak.d/50-on-gc";

  withApps = evalConfig [
    {
      modules.apps.flatpak = {
        enable = true;
        ensure = [
          "us.zoom.Zoom"
          "org.signal.Signal"
        ];
      };
    }
  ];
  appService = withApps.systemd.services.magi-flatpak-ensure-packages;
in {
  # Disabled means neither half exists, hook included: a host that doesn't opt
  # in must not have `magi gc` reach for flatpak.
  testDisabledByDefault = {
    expr = {
      service = off.systemd.services ? magi-flatpak-ensure-packages;
      hook = off.home.dataFile ? "magi/hooks.d/flatpak.d/50-on-gc";
    };
    expected = {
      service = false;
      hook = false;
    };
  };

  # A oneshot, not the default simple service: otherwise it drops to inactive
  # the moment the script returns, and a boot without network leaves a failed
  # unit behind. 30min keeps N installs plus an update from the 90s default.
  testEnsureUnitIsAOneshot = {
    expr = {
      inherit (service.serviceConfig) Type RemainAfterExit timeoutStartSec;
      inherit (service) wantedBy wants after;
    };
    expected = {
      Type = "oneshot";
      RemainAfterExit = true;
      timeoutStartSec = "30min";
      wantedBy = ["multi-user.target"];
      wants = ["network-online.target"];
      after = ["network-online.target"];
    };
  };

  # The repository has to exist before an install can, and the generation is
  # written last so a failure retries on the next boot instead of being
  # remembered as settled.
  testEnsureScriptRecordsOnlyAfterSucceeding = {
    expr = {
      remote = hasInfix "flatpak remote-add --if-not-exists flathub" service.script;
      update = hasInfix "flatpak update -y --noninteractive" service.script;
      records = hasInfix "printf '%s\\n' \"$system\"" service.script;
      # An empty ensure list means no install line at all.
      installs = hasInfix "flatpak install" service.script;
    };
    expected = {
      remote = true;
      update = true;
      records = true;
      installs = false;
    };
  };

  testEnsureInstallsWhatTheHostDeclares = {
    expr = {
      zoom = hasInfix "us.zoom.Zoom" appService.script;
      signal = hasInfix "org.signal.Signal" appService.script;
      installs = hasInfix "flatpak install -y --noninteractive --or-update flathub" appService.script;
    };
    expected = {
      zoom = true;
      signal = true;
      installs = true;
    };
  };

  # Generating the fragment is not enough: `magi hook` only searches the dirs
  # in magi.hookPaths, so a fragment no path names is a file nobody runs.
  testHookAreaIsSearched = {
    expr = elem "${on.home.dataDir}/magi/hooks.d/flatpak.d" on.magi.hookPaths;
    expected = true;
  };

  # A fragment like any other: zsh, executable, sequenced after the host's
  # unnumbered handlers, and no-op unless the system was swept too. The pruning
  # itself lives in the prune script it hands to sudo, which is a store path
  # (hence no reading it here).
  testHookOnlyPrunesOnSystemGc = {
    expr = {
      executable = hook.executable;
      zsh = hasPrefix "#!/usr/bin/env zsh\n" hook.text;
      guard = hasInfix ''[[ " $* " == *" system "* ]]'' hook.text;
      sudo = hasInfix "sudo /nix/store/" hook.text;
      prune = hasInfix "magi-flatpak-prune" hook.text;
    };
    expected = {
      executable = true;
      zsh = true;
      guard = true;
      sudo = true;
      prune = true;
    };
  };
}
