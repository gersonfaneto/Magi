# profiles/hardware/scanner --- SANE scanner support
{
  self,
  lib,
  config,
  ...
}:
with lib;
with self.lib; let
  hardware = config.modules.profiles.hardware;
in
  mkMerge [
    (mkIf (any (s: hasPrefix "scanner" s) hardware) {
      hardware.sane = {
        enable = true;
        openFirewall = true;
      };
      user.extraGroups = ["scanner"];
    })
  ]
