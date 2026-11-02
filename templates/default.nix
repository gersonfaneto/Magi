# templates/default.nix --- start a new flake from these dotfiles
#
# Leaves hosts/ behind, since those are machine-specific.
{
  default = {
    description = "Magi, minus its host configs";
    welcomeText = ''
      Define a host under hosts/ (see hosts/README.md), then deploy it with:

          nix --extra-experimental-features "nix-command flakes" \
            --option accept-flake-config true \
            run github:gersonfaneto/Magi#install
    '';
    path = builtins.path {
      name = "magi";
      path = ../.;
      filter = path: type: let
        root = toString ../.;
        base = baseNameOf path;
      in
        !(
          # Hosts are per-machine; keep the README and .git-keep only.
          (type == "directory" && dirOf path == toString ../hosts)
          # Never copy the checkout's own history or build artifacts.
          || base == ".git"
          || (type == "directory" && base == "build" && dirOf path == root)
          || (type == "symlink" && base == "result")
        );
    };
  };
}
