# modules/system/battery.nix --- laptop battery monitoring and low-battery policy
#
# UPower owns the percentages and the final safety net; `magi battery watch`
# owns the warnings and the grace period before hibernating. The daemon runs as
# a systemd user service so it can talk to the session's notification server,
# lock the session, and hold a logind sleep inhibitor while the battery is
# critical.
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
  cfg = config.modules.system.battery;

  # UPower's own action fires a little below the daemon's, so a dead daemon
  # still hibernates instead of draining the battery to zero.
  upowerAction = max 1 (cfg.action - 2);

  upowerStrategy =
    {
      hibernate = "Hibernate";
      hybrid-sleep = "HybridSleep";
      poweroff = "PowerOff";
    }.${
      cfg.strategy
    };

  # `magi` resolves child commands through MAGI_BATTERY_PATH instead of $PATH,
  # which it replaces with its login-session cache. Share one list between
  # interactive `magi battery status` and the user service.
  batteryPath = lib.makeBinPath (with pkgs; [
    coreutils
    libnotify
    sox
    systemd
    upower
  ]);
in {
  options.modules.system.battery = with types; {
    enable = mkOpt' bool false "Enable battery monitoring and the low-battery policy.";
    low = mkOpt' int 20 "Percentage at which to warn that the battery is low.";
    critical = mkOpt' int 10 "Percentage at which to warn critically and guard sleep.";
    action = mkOpt' int 5 "Percentage at which to run the critical action after `grace` seconds.";
    grace = mkOpt' int 60 "Seconds to wait at `action` before hibernating, so a charger can be plugged in.";
    strategy = mkOpt' (enum ["hibernate" "hybrid-sleep" "poweroff"]) "hibernate" "What to do at `action`.";
    guardSleep =
      mkOpt' bool true
      "Hold a logind sleep inhibitor at `critical`, so lid close and idle suspend cannot drain the battery.";
    sound = mkOpt' bool true "Play the notification sounds along with the warnings.";
    notify = mkOpt' bool true "Show desktop notifications for the warnings.";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = cfg.low > cfg.critical && cfg.critical > cfg.action && cfg.action >= 2;
          message = "modules.system.battery: low > critical > action, and action >= 2 (UPower needs a lower fallback).";
        }
      ];

      services.upower = {
        enable = true;
        usePercentageForPolicy = true;
        percentageLow = cfg.low;
        percentageCritical = cfg.critical;
        percentageAction = upowerAction;
        criticalPowerAction = upowerStrategy;
      };

      systemd.sleep.settings.Sleep.AllowHibernation = true;

      environment.sessionVariables.MAGI_BATTERY_PATH = batteryPath;

      # The daemon reads thresholds from magi's generated info.json, so the
      # policy and the CLI can't disagree.
      magi.info.battery = {
        inherit
          (cfg)
          low
          critical
          action
          grace
          strategy
          guardSleep
          sound
          notify
          ;
      };

      systemd.user.services.magi-battery = {
        description = "magi battery monitor";
        wantedBy = ["graphical-session.target"];
        partOf = ["graphical-session.target"];
        after = ["graphical-session.target"];
        # The daemon spawns busctl, systemctl, loginctl, systemd-inhibit,
        # notify-send and play; don't depend on the session PATH.
        enableDefaultPath = false;
        # magi reads its XDG state (the cached login PATH) and generated
        # info.json through these. The user manager usually has them, but a
        # service started before login shouldn't have to guess.
        environment = {
          XDG_BIN_HOME = config.home.binDir;
          XDG_CACHE_HOME = config.home.cacheDir;
          XDG_CONFIG_HOME = config.home.configDir;
          XDG_DATA_HOME = config.home.dataDir;
          XDG_STATE_HOME = config.home.stateDir;
          # `magi` replaces $PATH with its cached login PATH, which a user
          # unit's `path` never reaches. Point its child-command lookup here.
          MAGI_BATTERY_PATH = batteryPath;
        };
        path = with pkgs; [
          coreutils
          libnotify
          sox
          systemd
          upower
        ];
        serviceConfig = {
          ExecStart = "${config.magi.bin} battery watch";
          Restart = "always";
          RestartSec = 5;
        };
      };
    }
  ]);
}
