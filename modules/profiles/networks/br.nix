# modules/profiles/networks/br.nix --- Brazil

{ self, lib, config, pkgs, ... }:

with lib;
with self.lib;
mkIf (elem "br" config.modules.profiles.networks) {
  time.timeZone = "America/Bahia";
}