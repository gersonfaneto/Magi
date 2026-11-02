# modules/wm/palette.nix
#
# The Nix-owned palettes. The Quickshell pill, the lock, and every rendered
# template read the bundle theme.py copies to
# $XDG_STATE_HOME/quickshell/palettes/current.json. The Nix side builds one
# bundle per scheme/tone from the canonical config/theme/themes/*.toml corpus,
# so the scheme registry is the only list to edit.
{
  self,
  lib,
  config,
  ...
}:
with lib;
with self.lib; let
  registry = builtins.fromJSON (builtins.readFile "${self.configDir}/theme/schemes.json");
  schemes = builtins.attrNames registry.schemes;

  tones = name:
    builtins.filter
    (tone: builtins.pathExists "${self.configDir}/theme/themes/${name}-${tone}.toml")
    ["dark" "light"];

  keys = concatMap (name: map (tone: "${name}-${tone}") (tones name)) schemes;

  palettes = self.packages.theme-palettes;
in {
  config = mkIf (config.modules.wm.desktop == "hyprland") {
    assertions = [
      {
        assertion = all (name: tones name != []) schemes;
        message = "config/theme/schemes.json lists a scheme with no colors.toml";
      }
    ];

    home.stateLink = listToAttrs (
      map (key: nameValuePair "quickshell/palettes/${key}.json" "${palettes}/${key}.json") keys
    );
  };
}
