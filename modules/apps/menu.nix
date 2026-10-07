{
  self,
  lib,
  config,
  options,
  pkgs,
  ...
}:
with builtins;
with lib; let
  inherit (self.lib.pkgs) mkLauncherEntry;

  cfg = config.modules.apps.menu;
in {
  options.modules.apps.menu = with self.lib.options; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # The menus are `magi @menu ...` scripts, rendered by fsel in a floating
      # foot window. Only the tabler-icon SVGs need fetching; the name table and
      # the emoji lists ride in the checkout.
      home.dataFile."magi/tabler-icons".source = let
        src = pkgs.fetchFromGitHub {
          owner = "tabler";
          repo = "tabler-icons";
          rev = "v3.34.0";
          sparseCheckout = ["icons"]; # 3.5M of a 50M repo
          hash = "sha256-oP6nfTHlMVT6nO+ntSQFewBT2hMCkm2rq4+pTlAtYs8=";
        };
      in
        pkgs.runCommand "tabler-icons" {} ''
          mkdir -p $out
          cp -t $out ${src}/icons/outline/*.svg
          for f in ${src}/icons/filled/*.svg; do
            cp "$f" "$out/$(basename "$f" .svg)-filled.svg"
          done
        '';

      user.packages = with pkgs; [
        (mkLauncherEntry "Open Bookmark ->" {
          description = "In ${config.modules.apps.browsers.default}";
          icon = "bookmark-new-symbolic";
          exec = "foot --app-id=magi-menu -e magi @menu bookmark";
        })
        (mkLauncherEntry "Copy Icon ->" {
          icon = "icons";
          exec = "foot --app-id=magi-menu -e magi @menu icon";
        })
        (mkLauncherEntry "Open File ->" {
          icon = "folder";
          exec = "foot --app-id=magi-menu -e magi @menu file";
        })
        (mkLauncherEntry "Open Directory in Terminal ->" {
          icon = "folder";
          exec = "foot --app-id=magi-menu -e magi @menu file --dirs";
        })
        (mkLauncherEntry "Emoji Selector ->" {
          icon = "face-smile";
          exec = "foot --app-id=magi-menu -e magi @menu emoji";
        })
      ];
    }

    (mkIf config.hardware.bluetooth.enable {
      user.packages = [
        (mkLauncherEntry "Manage Bluetooth Devices ->" {
          icon = "bluetooth";
          exec = "foot -e bluetoothctl";
        })
      ];
    })

    (mkIf (elem "wifi" config.modules.profiles.hardware) {
      user.packages = [
        (mkLauncherEntry "Connect to WiFi ->" {
          icon = "network-wireless";
          exec = "foot -e nmtui";
        })
      ];
    })

    (mkIf config.services.udisks2.enable {
      user.packages = [
        (mkLauncherEntry "Mount/unmount Devices ->" {
          icon = "drive-harddisk";
          exec = "foot --app-id=magi-menu -e magi @menu mount";
        })
      ];
    })
  ]);
}
