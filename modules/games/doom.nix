# modules/games/doom.nix --- GZDoom and Steam's Doom 2
#
# Brutal Doom and friends aren't in nixpkgs and can't be fetched: ModDB serves
# downloads through mirror redirects with nothing stable to pin. So the pk3s
# sit in wadsDir and nix only tells gzdoom where to look.
{
  self,
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with self.lib; let
  cfg = config.modules.games.doom;
  steam = config.modules.apps.steam;
  libraryDir =
    if steam.libraryDir != ""
    then steam.libraryDir
    else "${config.home.dataDir}/Steam";
in {
  options.modules.games.doom = with types; {
    enable = mkBoolOpt false;
    # Steam's classic Doom 2 (app 2300). The 2024 "DOOM + DOOM II" re-release
    # (app 2280) lays its WADs out differently; point this at one of those if
    # that's what gets installed.
    iwad = mkOpt str "${libraryDir}/steamapps/common/Doom 2/base/DOOM2.WAD";
    # Where the pk3s and pwads are. Nothing here creates or fills it.
    wadsDir = mkOpt str "${config.home.dataDir}/games/doom";
  };

  config = mkIf cfg.enable {
    user.packages = [pkgs.gzdoom];

    magi.info.doom = {inherit (cfg) iwad wadsDir;};

    environment.sessionVariables.DOOMWADDIR = dirOf cfg.iwad;
  };
}
