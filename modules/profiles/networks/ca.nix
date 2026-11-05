# modules/profiles/networks/ca.nix --- Canada locale defaults
{
  self,
  lib,
  config,
  ...
}:
with lib;
with self.lib;
  mkIf (elem "ca" config.modules.profiles.networks) {
    time.timeZone = "America/Toronto";
  }
