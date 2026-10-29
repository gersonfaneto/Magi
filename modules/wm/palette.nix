# modules/wm/palette.nix
#
# The Nix-owned palettes. The Quickshell pill, the lock, and every rendered
# template read the bundle theme.py copies to
# $XDG_STATE_HOME/quickshell/palettes/current.json. The Nix side builds the
# fixed washi identity and one bundle per scheme/tone from
# config/theme/schemes.json, so the scheme registry is the only list to edit.
#
# The wallpaper source is a runtime bundle from wallcolors.py; the same role
# set and terminal section, written to the same directory.
{
  self,
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with self.lib; let
  registry = builtins.fromJSON (builtins.readFile "${self.configDir}/theme/schemes.json");
  schemes =
    builtins.filter
    (name: !(registry.schemes.${name}.identity or false))
    (builtins.attrNames registry.schemes);

  keys = ["washi"] ++ concatMap (name: ["${name}-dark" "${name}-light"]) schemes;

  palettes =
    pkgs.runCommand "quickshell-palettes" {
      nativeBuildInputs = [pkgs.python3];
    } ''
      python3 ${self.configDir}/hypr/scripts/quickshell-palette.py \
        --themes ${self.configDir}/foot/themes \
        --schemes ${self.configDir}/theme/schemes.json \
        --out $out
    '';
in {
  config = mkIf (config.modules.wm.desktop == "hyprland") {
    home.stateLink = listToAttrs (
      map (key: nameValuePair "quickshell/palettes/${key}.json" "${palettes}/${key}.json") keys
    );
  };
}
