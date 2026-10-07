# test/nixos/installer.nix --- tests for installer/ and install.zsh's inputs
#
# The installer scaffolds new hosts out of installer/host-template.nix onto
# installer/disko-single.nix. Both are plain data/functions, so pin them here:
# the layout's shape, the template's wiring, and a full evaluation of a
# scaffolded host (the closest `hey test nixos` gets to a trial install).
{
  lib,
  evalSystem',
  mkHey,
  ...
}:
with lib; let
  self = mkHey {};
  layout = import ../../installer/disko-single.nix {
    device = "/dev/vda";
    swapSize = "8G";
  };
  partitions = layout.disko.devices.disk.main.content.partitions;

  apply = args: import ../../installer/host-template.nix ({inherit lib self;} // args);

  baseArgs = {
    hostName = "testbox";
    user = "gerson";
    role = "workstation";
    desktop = "hyprland";
    networks = ["ca"];
    hardware = [
      "cpu/amd"
      "ssd"
    ];
    diskoConfig = {};
    hardwareConfig = {};
    userPasswordHash = "user-hash";
    rootPasswordHash = "root-hash";
  };
  host = apply baseArgs;

  evaluated = evalSystem' {
    hostName = "testbox";
    inherit host;
    extraModules = [{disko.devices = layout.disko.devices;}];
  };
in {
  testDiskoTargetsDevice = {
    expr = layout.disko.devices.disk.main.device;
    expected = "/dev/vda";
  };

  testDiskoEsp = {
    expr = with partitions.ESP; {
      inherit size;
      type = content.type;
      mountpoint = content.mountpoint;
    };
    expected = {
      size = "1G";
      type = "filesystem";
      mountpoint = "/boot";
    };
  };

  testDiskoSwap = {
    expr = with partitions.swap; {
      inherit size;
      type = content.type;
    };
    expected = {
      size = "8G";
      type = "swap";
    };
  };

  testDiskoRoot = {
    expr = with partitions.root; {
      inherit size;
      mountpoint = content.mountpoint;
      fsType = content.type;
    };
    expected = {
      size = "100%";
      mountpoint = "/";
      fsType = "filesystem";
    };
  };

  testDiskoFormatIsFstype = {
    # `format` is a bare fstype ("ext4"), not an mkfs command: disko derives
    # NixOS's fsType straight from it, so a command here breaks mounting.
    expr = {
      esp = partitions.ESP.content.format;
      root = partitions.root.content.format;
    };
    expected = {
      esp = "vfat";
      root = "ext4";
    };
  };

  testDiskoLabels = {
    expr = {
      esp = partitions.ESP.content.extraArgs;
      root = partitions.root.content.extraArgs;
    };
    expected = {
      esp = [
        "-F"
        "32"
        "-n"
        "BOOT"
      ];
      root = [
        "-L"
        "NIXOS"
      ];
    };
  };

  testDiskoSecretsRules = {
    # The scaffolded rules file must stay a valid, empty rule set: the
    # installer copies it verbatim and agenix reads it on first sync.
    expr = import ../../installer/secrets.nix;
    expected = {};
  };

  testTemplateSystem = {
    expr = host.system;
    expected = "x86_64-linux";
  };

  testTemplateProfiles = {
    expr = host.modules.profiles;
    expected = {
      role = "workstation";
      user = "gerson";
      networks = ["ca"];
      hardware = [
        "cpu/amd"
        "ssd"
      ];
    };
  };

  testTemplateDesktop = {
    expr = host.modules.wm.desktop;
    expected = "hyprland";
  };

  testTemplateServerOmitsWm = {
    expr =
      (apply (
        baseArgs
        // {
          role = "server";
          desktop = null;
        }
      )).modules
      ? wm;
    expected = false;
  };

  testTemplatePasswords = {
    expr = let
      cfg = host.config {};
    in {
      user = cfg.user.hashedPassword;
      root = cfg.users.users.root.hashedPassword;
    };
    expected = {
      user = "user-hash";
      root = "root-hash";
    };
  };

  testTemplateNoPasswords = {
    expr = let
      cfg =
        (apply (
          baseArgs
          // {
            userPasswordHash = null;
            rootPasswordHash = null;
          }
        )).config
        {};
    in {
      user = cfg.user.hashedPassword;
      root = cfg.users.users.root.hashedPassword;
    };
    expected = {
      user = null;
      root = null;
    };
  };

  testScaffoldedHostEvaluates = {
    expr = isString evaluated.config.system.build.toplevel.drvPath;
    expected = true;
  };

  # The VM trial installs a server-role scaffold; prove that shape evaluates
  # too (workstation coverage above doesn't imply it).
  testScaffoldedServerEvaluates = let
    server = apply (
      baseArgs
      // {
        role = "server";
        desktop = null;
      }
    );
    sys = evalSystem' {
      hostName = "testbox";
      host = server;
      extraModules = [{disko.devices = layout.disko.devices;}];
    };
  in {
    expr = isString sys.config.system.build.toplevel.drvPath;
    expected = true;
  };

  # melchior's disk was never GPT-named, so its content blocks must address
  # filesystems by label (which exists); disko's by-partlabel default would
  # point at nodes that aren't there. Lock that property here.
  testMelchiorDiskoDevice = let
    mel = (import ../../hosts/melchior/disko.nix).disko.devices.disk.main;
  in {
    expr = mel.device;
    expected = "/dev/nvme0n1";
  };

  testMelchiorDiskoByLabel = let
    parts = (import ../../hosts/melchior/disko.nix).disko.devices.disk.main.content.partitions;
  in {
    expr = {
      esp = parts.ESP.content.device;
      swap = parts.swap.content.device;
      root = parts.root.content.device;
    };
    expected = {
      esp = "/dev/disk/by-label/BOOT";
      swap = "/dev/disk/by-label/SWAP";
      root = "/dev/disk/by-label/NIXOS";
    };
  };

  testMelchiorDiskoFormats = let
    parts = (import ../../hosts/melchior/disko.nix).disko.devices.disk.main.content.partitions;
  in {
    expr = {
      esp = parts.ESP.content.format;
      swap = parts.swap.content.type;
      root = parts.root.content.format;
    };
    expected = {
      esp = "vfat";
      swap = "swap";
      root = "ext4";
    };
  };
}
