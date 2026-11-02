# installer/disko-single.nix --- the installer's default single-disk layout
#
# A parameterized disko configuration: one GPT disk with an EFI system
# partition, a swap partition, and the rest as root. Fresh hosts scaffolded by
# install.zsh import this (via their own disko.nix, which pins the device), so
# the layout lives here, not copy-pasted per host.
#
# NOTE on disko's schema: `format` is a bare filesystem type ("ext4", not an
# mkfs command); extra mkfs arguments (like labels) go in `extraArgs`, and
# disko derives NixOS's fsType straight from `format`.
#
# Run it directly against a target disk:
#
#   disko --mode disko /path/to/host/disko.nix
#
# Hosts with their own layout needs keep their own disko.nix (melchior's
# predates disko conventions); scaffolded hosts and the reinstall fallback
# share this one instead of duplicating it.
{
  device,
  swapSize ? "8G",
}: {
  disko.devices = {
    disk.main = {
      inherit device;
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
              mountpoint = "/boot";
              mountOptions = ["umask=0077"];
            };
          };
          swap = {
            size = swapSize;
            content = {
              type = "swap";
              randomEncryption = false;
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
              mountpoint = "/";
              mountOptions = [
                "noatime"
                "errors=remount-ro"
              ];
            };
          };
        };
      };
    };
  };
}
