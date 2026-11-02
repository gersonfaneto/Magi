# test/nixos/modules/battery.nix --- tests for modules/system/battery.nix
#
# UPower is the last line of defense and the daemon is the friendly layer in
# front of it. Pin both: the thresholds must agree with the daemon's info.json,
# the user service must be wired into the graphical session, and the laptop
# profile must turn the whole thing on without a host spelling it out.
{
  evalConfig,
  presets,
  lib,
  ...
}:
with lib; let
  on = evalConfig [{modules.system.battery.enable = true;}];
  off = evalConfig [];
  laptop = evalConfig [{modules.profiles.hardware = ["pc/laptop"];}];
  service = on.systemd.user.services.magi-battery;
in {
  testDisabledByDefault = {
    expr = off.systemd.user.services ? magi-battery;
    expected = false;
  };

  testLaptopEnables = {
    expr = {
      battery = laptop.modules.system.battery.enable;
      upower = laptop.services.upower.enable;
      service = laptop.systemd.user.services ? magi-battery;
    };
    expected = {
      battery = true;
      upower = true;
      service = true;
    };
  };

  testUpowerPolicy = {
    expr = {
      inherit (on.services.upower) percentageLow percentageCritical percentageAction criticalPowerAction;
      usePercentage = on.services.upower.usePercentageForPolicy;
      hibernate = on.systemd.sleep.settings.Sleep.AllowHibernation;
    };
    expected = {
      percentageLow = 20;
      percentageCritical = 10;
      percentageAction = 3;
      criticalPowerAction = "Hibernate";
      usePercentage = true;
      hibernate = true;
    };
  };

  testServiceWiring = {
    expr = {
      inherit (service) wantedBy;
      restart = service.serviceConfig.Restart;
      exec = hasInfix "battery watch" service.serviceConfig.ExecStart;
      defaultPath = service.enableDefaultPath;
      tools = all (prefix: hasInfix prefix service.environment.MAGI_BATTERY_PATH) [
        "-libnotify-"
        "-sox-"
        "-systemd-"
      ];
    };
    expected = {
      wantedBy = ["graphical-session.target"];
      restart = "always";
      exec = true;
      defaultPath = false;
      tools = true;
    };
  };

  # The CLI reads this, so a Nix threshold change has to reach info.json.
  testInfo = {
    expr = on.magi.info.battery;
    expected = {
      low = 20;
      critical = 10;
      action = 5;
      grace = 60;
      strategy = "hibernate";
      guardSleep = true;
      sound = true;
      notify = true;
    };
  };

  testMelchiorResumesFromSwap = {
    expr = presets.hosts.melchior.boot.resumeDevice;
    expected = "/dev/disk/by-label/SWAP";
  };
}
