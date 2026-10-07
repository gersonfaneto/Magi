# profiles/role/workstation.nix --- desktop/workstation tuning
{
  self,
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with self.lib;
  mkIf (config.modules.profiles.role == "workstation") (mkMerge [
    {
      boot = {
        # HACK I used to disable mitigations for spectre, meltdown, L1TF,
        #   retbleed, and other CPU vulnerabilities for a marginal performance
        #   gain on non-servers, but it really makes little to no difference on
        #   modern CPUs. It may still be worth it on older Xeons and the like (on
        #   workstations) though. I've preserved this in comments for future
        #   reference.
        #
        #   DO NOT COPY AND UNCOMMENT IT BLINDLY! If you're looking for
        #   optimizations, these aren't the droids you're looking for!
        # kernelParams = [ "mitigations=off" ];

        # Optimizations for desktops/gaming
        kernel.sysctl = {
          "kernel.sched_cfs_bandwidth_slice_us" = 3000;
          # Prevents intentional slowdowns in case games experience split locks This
          # is valid for kernels v6.0+
          "kernel.split_lock_mitigate" = 0;
        };

        loader = {
          # I'm not a big fan of Grub, so if it's not in use...
          systemd-boot.enable = mkDefault true;
          # For much quicker boot up to NixOS. Hold down a key to bring it up or
          # use `systemctl reboot --boot-loader-entry=X` instead.
          timeout = mkDefault 0;
        };

        # Common kernels across workstations
        initrd.availableKernelModules = [
          "xhci_pci" # USB 3.0
          "usb_storage" # USB mass storage devices
          "usbhid" # USB human interface devices
          "ahci" # SATA devices on modern AHCI controllers
          "sd_mod" # SCSI, SATA, and IDE devices
        ];
      };

      # NetworkManager owns association, DHCP, DNS and secrets for both wired
      # and wireless links. It replaced the old split stack (iwd for L2,
      # systemd-networkd for L3) so the TUI pickers can drive the whole
      # thing through NetworkManager's D-Bus API instead of shelling out to
      # iwctl. The old IPv6 privacy behaviour is preserved in the connection
      # defaults; NM's built-in route metrics already prefer wired over wifi.
      networking = {
        useDHCP = false;
        networkmanager = {
          enable = true;
          dns = "systemd-resolved";
          connectionConfig = {
            "ipv6.ip6-privacy" = 2; # prefer temporary addresses (networkd used kernel)
            "wifi.powersave" = 3; # NM's documented default, made explicit
          };
        };
      };

      # resolved keeps split-DNS working for Tailscale and VPNs; NM pushes its
      # DNS settings into it (dns = "systemd-resolved" above).
      services.resolved.enable = true;

      # No WWAN on workstations; NetworkManager pulls ModemManager in by default.
      networking.modemmanager.enable = false;

      # networkd's wait-online was already off; do the same for NM so a laptop
      # without a link does not hold up network-online.target.
      systemd.services.NetworkManager-wait-online.enable = false;

      user.extraGroups = ["networkmanager"];

      modules.xdg.ssh.enable = true;

      # A compressed swap device in RAM, so memory pressure degrades into slower
      # memory instead of straight into OOM.
      zramSwap.enable = mkDefault true;

      # OOM-kill memory hungry processes in userland too.
      systemd.oomd.enableUserSlices = true;
    }

    (mkIf config.modules.services.ssh.enable {
      programs.ssh.startAgent = true;
      services.openssh.startWhenNeeded = true;
    })

    # modules/wm/hyprland turns on power-profiles-daemon. This reverts to
    # the balanced profile on each startup, in case a bar widget changed it.
    (mkIf config.services.power-profiles-daemon.enable {
      # `balanced` defers to amd-pstate's firmware (full boost under load, actual
      # clock down at idle), which is superior to `performance`, which parks EPP
      # near max. My poor baby.
      magi.hooks."on-started".power-profile = "${getExe' config.services.power-profiles-daemon.package "powerprofilesctl"} set balanced";
    })

    # ...
  ])
