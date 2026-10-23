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

    # qutebrowser paints its own chrome, so the palette is rendered into a
    # theme.py that config.py sources. Like foot's theme.ini, it is regenerated
    # whenever the palette changes.
    modules.wm.theme.files.qutebrowser = {
      input_path = "${config.magi.configDir}/theme/qutebrowser.template.py";
      output_path = "${config.home.configDir}/qutebrowser/theme.py";
    };
  };
}
