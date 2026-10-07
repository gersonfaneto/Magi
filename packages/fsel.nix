{
  lib,
  fetchFromGitHub,
  rustPlatform,
  installShellFiles,
  pkg-config,
  ...
}:
rustPlatform.buildRustPackage {
  pname = "fsel";
  version = "4.0.0";

  src = fetchFromGitHub {
    owner = "Mjoyufull";
    repo = "fsel";
    tag = "4.0.0";
    hash = "sha256-+KzmiWJqtM6lJL/aWYvU2XuLT7k8FqTWsVWn8hWOMRc=";
  };

  cargoHash = "sha256-Vo3J2/XphNhvYkt4oasB2Z6OOj/nez7agSJZJbu+h1I=";

  # The launcher test module spawns helpers and waits on them; it fails or
  # hangs under the build sandbox. The remaining suites pass and the binary is
  # unaffected.
  doCheck = false;

  nativeBuildInputs = [
    installShellFiles
    pkg-config
  ];

  postInstall = ''
    installManPage fsel.1
  '';

  meta = {
    description = "Fast TUI app launcher and fuzzy finder for GNU/Linux and *BSD";
    homepage = "https://github.com/Mjoyufull/fsel";
    license = lib.licenses.bsd2;
    mainProgram = "fsel";
    platforms = with lib.platforms; linux ++ freebsd ++ openbsd ++ netbsd;
  };
}
