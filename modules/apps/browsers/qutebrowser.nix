# modules/apps/browsers/qutebrowser.nix --- https://qutebrowser.org/
#
# Qt6/WebEngine with vim keys. nixpkgs' package already drags in the qtwayland
# plugin, so it lands on Wayland unassisted; the Qt chrome takes its palette
# from modules/wm/theme.nix through QT_QPA_PLATFORMTHEME_QT6.
{
  self,
  lib,
  config,
  options,
  pkgs,
  ...
}:
with lib;
with self.lib; let
  cfg = config.modules.apps.browsers.qutebrowser;

  # QtWebEngine loads Chromium's .bdic dictionaries, not hunspell's .dic/.aff.
  # nixpkgs' hunspellDictsChromium only packages en/de/fr/sv, so pt-BR comes
  # from the same pinned checkout. Keep the codes in sync with
  # config/qutebrowser/config.py's spellcheck.languages.
  chromiumDicts = pkgs.fetchgit {
    url = "https://chromium.googlesource.com/chromium/deps/hunspell_dictionaries";
    rev = "cccf64a8acc951afe3f47fee023908e55699bc58";
    hash = "sha256-mYDPXa64IOKLMNiBiMqDrQMR7gDPI+vdyVc+M7E+ddc=";
  };
  dictionaries = pkgs.runCommand "qutebrowser-dictionaries" {} ''
    mkdir -p $out
    cp -t $out ${chromiumDicts}/en-US-*.bdic ${chromiumDicts}/pt-BR-*.bdic
  '';
in {
  options.modules.apps.browsers.qutebrowser = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = [
      (pkgs.qutebrowser.override {
        enableWideVine = true;
      })
      (mkLauncherEntry "Qutebrowser (Private)" {
        description = "Open a private qutebrowser window";
        icon = "qutebrowser";
        exec = "qutebrowser --target private-window";
        categories = ["Network"];
      })
    ];

    # Only config.py is linked, so autoconfig.yml, sessions and history live in
    # ~/.config/qutebrowser instead of dirtying the checkout. Quickmarks are
    # plain text, so they can be shared with the repo.
    home.configLink = {
      "qutebrowser/config.py" = "${config.magi.configDir}/qutebrowser/config.py";
      "qutebrowser/quickmarks" = "${config.magi.configDir}/qutebrowser/quickmarks";
    };

    home.dataLink."qutebrowser/qtwebengine_dictionaries" = "${dictionaries}";

    # qutebrowser paints its own chrome, so the palette is rendered into a
    # theme.py that config.py sources. Like foot's theme.ini, it is regenerated
    # whenever the palette changes.
    modules.wm.theme.files.qutebrowser = {
      input_path = "${config.magi.configDir}/theme/qutebrowser.template.py";
      output_path = "${config.home.configDir}/qutebrowser/theme.py";
    };
  };
}
