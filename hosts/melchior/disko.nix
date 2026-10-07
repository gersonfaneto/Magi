# hosts/melchior/disko.nix --- this machine's disk, as disko sees it
#
# Mirrors the live layout exactly: 1G ESP, 16G swap, rest root. The NixOS side
# (fileSystems, swapDevices) is generated from this, and install.zsh
# reformats from it on reinstall.
#
# The partitions were never given GPT names, so there are no by-partlabel
# nodes for them; every content block therefore addresses its filesystem by
# LABEL (which exists live and is recreated by extraArgs on reinstall)
# instead of disko's by-partlabel default.
#
# DANGER: `disko --mode disko` against this file wipes /dev/nvme0n1. That is
# only ever what you want when reinstalling this host from the ISO.
{
  disko.devices = {
    disk.main = {
      device = "/dev/nvme0n1";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              extraArgs = [
                "-F"
                "32"
                "-n"
                "BOOT"
              ];
              device = "/dev/disk/by-label/BOOT";
              mountpoint = "/boot";
              mountOptions = [
                "fmask=0022"
                "dmask=0022"
              ];
            };
          };
          swap = {
            size = "16G";
            content = {
              type = "swap";
              randomEncryption = false;
              device = "/dev/disk/by-label/SWAP";
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              extraArgs = [
                "-L"
                "NIXOS"
              ];
              device = "/dev/disk/by-label/NIXOS";
              mountpoint = "/";
              # No mountOptions: disko's ["defaults"] is what the kernel
              # applies anyway, matching the option-less config this replaces.
            };
          };
        };
      };
    };
  };
}
