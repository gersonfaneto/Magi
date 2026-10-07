# modules/profiles/hardware/gpu/amd.nix --- amdgpu: just works

{ self, lib, config, pkgs, ... }:

with lib;
with self.lib;
let hardware = config.modules.profiles.hardware;
in mkIf (any (s: hasPrefix "gpu/amd" s) hardware) {
  hardware.graphics = {
    enable = true;
    # For wine/Steam and other 32-bit OpenGL/Vulkan clients.
    enable32Bit = true;
  };
}