{
  self,
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.apps.menu;
in {
  options.modules.apps.menu = with self.lib.options; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    # The menus are `magi @menu ...` scripts, reached through the launcher's
    # bang table (`!file`, `!bookmark`, ...), not as app entries. Only the
    # tabler-icon SVGs need fetching; their name table rides in the checkout.
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
  };
}
