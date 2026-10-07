# modules/wm/palette.nix
#
# The Nix-owned palettes. Every template reads the bundle theme.py copies to
# $XDG_STATE_HOME/magi/theme/palettes/current.json. The Nix side builds one
# bundle per tone from config/foot/themes/mono-{dark,light}.ini.
{
  self,
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with self.lib; let
  tones = ["dark" "light"];

  palettes =
    pkgs.runCommand "magi-palettes" {
      nativeBuildInputs = [pkgs.python3];
    } ''
      python3 ${self.configDir}/hypr/scripts/palette.py \
        --themes ${self.configDir}/foot/themes \
        --out $out
    '';
in {
  config = mkIf (config.modules.wm.desktop == "hyprland") {
    home.stateLink = listToAttrs (
      map (tone: nameValuePair "magi/theme/palettes/mono-${tone}.json" "${palettes}/mono-${tone}.json") tones
    );
  };
}
