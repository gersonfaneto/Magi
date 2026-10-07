# melchior -- my ThinkPad T495 workstation

{ self, lib, ... }:

with lib;
with builtins;
{
  system = "x86_64-linux";

  imports = [
    self.modules.nixos-hardware.lenovo-thinkpad-t495
  ];

  ## Flake modules
  modules = {
    xdg.ssh.enable = true;

    profiles = {
      role = "workstation";
      user = "gerson";
      networks = [ "br" ];
      hardware = [
        "cpu/amd"
        "gpu/amd"
        "wifi"
        "pc/laptop"
        "audio"
        "ssd"
        "bluetooth"
      ];
    };

    wm = {
      desktop = "hyprland";
      theme.fonts.mono = "CommitMono";
      plymouth = {
        enable = true;
        seamless = true;
      };
      hyprland = {
        monitors = [{ output = "eDP-1"; primary = true; }];
        extraConfig = ''
          hl.config({
            input = {
              kb_layout = "br",
              kb_variant = "thinkpad",
              kb_options = "compose:ralt",
            }
          })
        '';
      };
    };

    ai.enable = true;

    apps = {
      term.default = "foot";
      term.foot.enable = true;

      flatpak.enable = true;
      rofi.enable = true;
      steam.enable = true;

      browsers.default = "librewolf";
      browsers.librewolf.enable = true;
      media.cad.enable = true;
      media.graphics.enable = true;
      media.music.enable = true;
      media.video.enable = true;
    };
    dev = {
      cc.enable = true;
      lua.enable = true;
      rust.enable = true;
      node.enable = true;
    };
    editors = {
      default = "nvim";
      vim.enable = true;
    };
    shell = {
      direnv.enable = true;
      git.enable = true;
      gnupg.enable = true;
      tmux.enable = true;
      zsh.enable = true;
      yazi.enable = true;
    };
    services = {
      ssh.enable = true;
    };
    system = {
      utils.enable = true;
    };
  };

  ## Local config
  config = { pkgs, ... }: {
    # Additive: keeps theme.nix defaults, adds CommitMono on top.
    # For a full replacement set `modules.wm.theme.fonts.packages` instead.
    modules.wm.theme.fonts.extraPackages = with pkgs; [ commit-mono ];

    console.keyMap = "br-abnt2";

    services.xserver.xkb = {
      layout = "br";
      variant = "thinkpad";
    };

    # Tapping the power button should do nothing.
    services.logind.settings.Login.HandlePowerKey = "ignore";
  };

  ## Hardware config
  hardware = { ... }: {
    boot.initrd.availableKernelModules = [ "nvme" "ehci_pci" "rtsx_pci_sdmmc" ];
    boot.kernelModules = [ "kvm-amd" ];

    # Cap the battery charge for longevity. Always plugged in anyway.
    services.udev.extraRules = ''
      ACTION=="add|change", SUBSYSTEM=="power_supply", KERNEL=="BAT*", ATTR{charge_control_end_threshold}=="?*", ATTR{charge_types}="Custom", ATTR{charge_control_end_threshold}="80"
    '';

    fileSystems = {
      "/" = {
        device = "/dev/disk/by-uuid/c06127b7-bd47-4e37-80ce-d2575d5ce24c";
        fsType = "btrfs";
        options = [ "noatime" "x-initrd.mount" ];
      };
      "/home" = {
        device = "/dev/disk/by-uuid/c06127b7-bd47-4e37-80ce-d2575d5ce24c";
        fsType = "btrfs";
        options = [ "subvol=home" "noatime" ];
      };
      "/nix" = {
        device = "/dev/disk/by-uuid/c06127b7-bd47-4e37-80ce-d2575d5ce24c";
        fsType = "btrfs";
        options = [ "subvol=nix" "noatime" "x-initrd.mount" ];
      };
      "/boot" = {
        device = "/dev/disk/by-uuid/18AC-3F99";
        fsType = "vfat";
        options = [ "fmask=0077" "dmask=0077" ];
      };
    };
    swapDevices = [{ device = "/dev/disk/by-uuid/db462724-88c8-4401-b1de-251ae790a9b8"; }];
  };
}
