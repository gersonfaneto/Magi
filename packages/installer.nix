# packages/installer.nix -- the installer behind `nix run .#install`
#
# Ships install.zsh (at the repo root) with the tools it needs on a stock
# installer ISO, where neither zsh nor git are guaranteed to be around. A
# hand-written wrapper (rather than wrapProgram) so $0 still points at the
# real script, whose header comment is its own --help text.
{
  lib,
  stdenvNoCC,
  zsh,
  git,
  disko,
  nixos-install-tools,
  util-linux,
  e2fsprogs,
  dosfstools,
  whois,
  # mkpasswd
  nix,
  coreutils,
  gawk,
  gnused,
  gnugrep,
  ...
}: let
  deps = [
    zsh
    git
    disko
    nixos-install-tools
    util-linux
    e2fsprogs
    dosfstools
    whois
    nix
    coreutils
    gawk
    gnused
    gnugrep
  ];
in
  stdenvNoCC.mkDerivation {
    name = "magi-installer";
    src = ../install.zsh;
    dontUnpack = true;
    installPhase = ''
      runHook preInstall
      install -Dm755 "$src" "$out/share/install/install.zsh"
      mkdir -p "$out/bin"
      cat >"$out/bin/install" <<EOF
      #!${stdenvNoCC.shell}
      export PATH="${lib.makeBinPath deps}:\$PATH"
      exec ${lib.getExe zsh} "$out/share/install/install.zsh" "\$@"
      EOF
      chmod 755 "$out/bin/install"
      runHook postInstall
    '';
    meta = with lib; {
      description = "Guided installer for this flake (disko + host scaffolding)";
      mainProgram = "install";
      platforms = ["x86_64-linux"];
    };
  }
