# packages/mono-icons.nix -- grayscale icon themes for the monochrome rice.
#
# Papirus is the shape language; this copies its light- and dark-background
# themes and rewrites every literal SVG colour to its luminance gray. The
# result installs as Mono (for the light variant) and Mono-Dark (for the dark
# one), keeping the directory structure so icon lookup carries on working.
{
  lib,
  stdenvNoCC,
  papirus-icon-theme,
  python3,
  ...
}:
stdenvNoCC.mkDerivation {
  pname = "magi-mono-icons";
  version = "1";

  dontUnpack = true;

  nativeBuildInputs = [python3];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/icons
    cp -a ${papirus-icon-theme}/share/icons/Papirus $out/share/icons/Mono
    # Papirus-Dark is a partial overlay full of "../Papirus/..." symlinks.
    # _mono-icons.py retargets those at Mono, which holds the base tree.
    cp -a ${papirus-icon-theme}/share/icons/Papirus-Dark $out/share/icons/Mono-Dark
    chmod -R u+w $out/share/icons
    python3 ${./_mono-icons.py} $out/share/icons/Mono $out/share/icons/Mono-Dark
    # Papirus ships a cache computed from the coloured SVGs; let consumers
    # rescan the grayscale tree instead of trusting it.
    find $out/share/icons -name icon-theme.cache -delete

    runHook postInstall
  '';

  meta = {
    description = "Grayscale Papirus icon themes for the Magi monochrome rice";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
