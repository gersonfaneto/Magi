# melchior -- my ThinkPad T495 workstation
{
  self,
  lib,
  ...
}:
with lib;
with builtins; {
  system = "x86_64-linux";

  imports = [
    self.modules.nixos-hardware.lenovo-thinkpad-t495
    self.inputs.disko.nixosModules.disko
    ./disko.nix
  ];

  ## Flake modules
  modules = {
    xdg.ssh.enable = true;

    profiles = {
      role = "workstation";
      user = "gerson";
      networks = ["br"];
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
      quickshell.enable = true;
      theme.fonts.mono = "Fantasque Sans Mono";
      plymouth = {
        enable = true;
        seamless = true;
      };
      hyprland = {
        monitors = [
          {
            output = "eDP-1";
            primary = true;
          }
        ];
      };
    };

    ai.enable = true;
    ai.opencode.enable = true;

    virt.docker.enable = true;

    apps = {
      term.default = "foot";
      term.foot.enable = true;

      flatpak.enable = true;
      menu.enable = true;
      steam.enable = true;
      thunar.enable = true;

      libreoffice.enable = true;

      browsers.default = "chromium";
      browsers.chromium.enable = true;
      browsers.qutebrowser.enable = true;

      media.graphics.enable = true;
      media.music.enable = true;
      media.video.enable = true;
      media.pdf.enable = true;
    };
    dev = {
      cc.enable = true;
      lua.enable = true;
      zig.enable = true;
      rust.enable = true;
      node.enable = true;
    };
    editors = {
      default = "nvim";
      vim.enable = true;
      vim.nerdFonts = true;
      emacs.enable = true;
    };
    shell = {
      direnv.enable = true;
      git.enable = true;
      gnupg.enable = true;
      tmux.enable = true;
      zsh.enable = true;
      ranger.enable = true;
      search.enable = true;
      pandoc.enable = true;
      scripts.enable = true;
      vaultwarden.enable = true;
    };
    services = {
      ssh.enable = true;
    };
    system = {
      utils.enable = true;
    };
  };

  ## Local config
  config = {pkgs, ...}: {
    modules.wm.theme.fonts.extraPackages = with pkgs; [
      fantasque-sans-mono
      nerd-fonts.fantasque-sans-mono

      departure-mono
      nerd-fonts.departure-mono
    ];

    console.keyMap = "br-abnt2";

    services.xserver.xkb = {
      layout = "br";
      variant = "thinkpad";
    };

    # Tapping the power button should do nothing.
    services.logind.settings.Login.HandlePowerKey = "ignore";
  };

  ## Hardware config
  hardware = {...}: {
    boot.initrd.availableKernelModules = [
      "nvme"
      "ehci_pci"
      "rtsx_pci_sdmmc"
    ];
    boot.kernelModules = ["kvm-amd"];

    # Hibernation writes the session image to the swap partition. Without this
    # the kernel has no resume device to read it back from.
    boot.resumeDevice = "/dev/disk/by-label/SWAP";

    # Cap the battery charge for longevity. Always plugged in anyway.
    services.udev.extraRules = ''
      ACTION=="add|change", SUBSYSTEM=="power_supply", KERNEL=="BAT*", ATTR{charge_control_end_threshold}=="?*", ATTR{charge_types}="Custom", ATTR{charge_control_end_threshold}="80"
    '';

    # fileSystems and swapDevices come from ./disko.nix (via the disko
    # module imported above), which mirrors the live layout.
  };
}
