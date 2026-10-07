# profiles/hardware/wifi.nix --- wifi via NetworkManager
#
# NetworkManager owns association (through wpa_supplicant, its default backend)
# and L3; the workstation role enables the daemon, resolved and the
# networkmanager group. This profile only pins the supplicant backend so a host
# can opt out of wireless support without touching the rest of the stack.
{
  self,
  lib,
  config,
  ...
}:
with lib;
with self.lib;
  mkIf (elem "wifi" config.modules.profiles.hardware) {
    networking.networkmanager.wifi.backend = "wpa_supplicant";
  }
