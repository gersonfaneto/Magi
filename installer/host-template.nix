# installer/host-template.nix --- the module behind every scaffolded host
#
# install.zsh renders hosts/<name>/default.nix as a thin pinning of this
# function (names, passwords, device), so scaffolded hosts share one tested
# module instead of copy-pasted snowflakes. diskoConfig and hardwareConfig are
# passed in rather than imported here so their paths resolve against the
# rendered default.nix (hosts/<name>/), not against this file.
{
  self,
  lib,
  hostName,
  user,
  role,
  # "workstation" | "server"
  desktop ? null,
  # e.g. "hyprland"; workstations only
  networks ? [],
  hardware ? [],
  diskoConfig,
  hardwareConfig,
  userPasswordHash ? null,
  rootPasswordHash ? null,
}:
with lib; {
  system = "x86_64-linux";

  imports = [
    self.inputs.disko.nixosModules.disko
    diskoConfig
    hardwareConfig
  ];

  modules =
    {
      profiles = {
        inherit
          role
          user
          networks
          hardware
          ;
      };

      shell = {
        git.enable = true;
        gnupg.enable = true;
        zsh.enable = true;
      };
      services.ssh.enable = true;
      system.utils.enable = true;
    }
    // optionalAttrs (role == "workstation") {
      wm.desktop = desktop;
    };

  config = {...}: {
    # Per-user modules (modules/profiles/user/*) set user.name for the users
    # they know; this covers everybody else, at lower precedence. Plain `if`s
    # (not mkIf) so the scaffold stays assertable without a full evaluation.
    user.name = mkDefault user;
    user.hashedPassword =
      if userPasswordHash != null
      then userPasswordHash
      else null;
    users.users.root.hashedPassword =
      if rootPasswordHash != null
      then rootPasswordHash
      else null;
  };

  hardware = {...}: {
    # The installer targets UEFI; BIOS and exotic bootloaders stay manual.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
