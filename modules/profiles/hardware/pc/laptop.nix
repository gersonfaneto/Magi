# profiles/hardware/pc/laptop.nix --- laptop power and backlight tools
{
  self,
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with self.lib; let
  hardware = config.modules.profiles.hardware;
in
  mkMerge [
    (mkIf (any (s: hasPrefix "pc/laptop" s) hardware) {
      # The battery module owns UPower and the low-battery policy. The shell
      # reads battery state from UPower over DBus.
      modules.system.battery.enable = true;

      user.packages = with pkgs; [
        brightnessctl # instead of programs.light
        acpi
      ];
    })
  ]
