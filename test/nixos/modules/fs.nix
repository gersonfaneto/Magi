# test/nixos/modules/fs.nix --- tests for modules/system/fs.nix
#
# zfs.enable follows the root filesystem rather than a flag, so this suite
# stands in a zfs root and reads the branch that only exists because of it.
# The zfs.mail option is the one that used to be referenced without being
# declared; nothing forced it while its block was empty.
{
  evalConfig,
  lib,
  ...
}: let
  zfs = evalConfig [
    {
      fileSystems."/".fsType = lib.mkForce "zfs";
    }
  ];
in {
  testZfsIsDetectedFromFileSystems = {
    expr = zfs.modules.system.fs.zfs.enable;
    expected = true;
  };

  # The options inside the zfs branch are what force its mkIf chain; reading
  # them all means a typo in an option name surfaces here, not on a real host.
  testZfsBranchEvaluates = {
    expr = {
      copyKernels = zfs.boot.loader.grub.copyKernels;
      scrub = zfs.services.zfs.autoScrub.enable;
      mail = zfs.modules.system.fs.zfs.mail.enable;
    };
    expected = {
      copyKernels = true;
      scrub = true;
      mail = false;
    };
  };
}
