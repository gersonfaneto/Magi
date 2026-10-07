# overlays/fsel.nix
#
# fsel 4 is the first release whose dmenu mode can preview images, which the
# clipboard and wallpaper pickers rely on. nixpkgs still packages 3.6.0, so
# carry the release here until it catches up.
final: prev: {
  fsel = final.callPackage ../packages/fsel.nix {};
}
