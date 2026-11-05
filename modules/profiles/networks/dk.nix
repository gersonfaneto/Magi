# modules/profiles/networks/dk.nix --- Denmark locale defaults
{
  self,
  lib,
  config,
  ...
}:
with lib;
with self.lib;
  mkIf (elem "dk" config.modules.profiles.networks) {
    time.timeZone = "Europe/Copenhagen";
  }
