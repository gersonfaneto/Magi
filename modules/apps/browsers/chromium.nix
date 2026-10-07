# modules/apps/browsers/chromium.nix --- https://www.chromium.org/
#
# Thin wrapper around nixpkgs' programs.chromium, which only manages
# /etc/chromium/policies -- it does not install the browser itself.
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
  cfg = config.modules.apps.browsers.chromium;
in {
  options.modules.apps.browsers.chromium = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      (chromium.override {
        enableWideVine = true;
      })
    ];

    programs.chromium.enable = true;

    programs.chromium.extraOpts = {
      "BookmarkBarEnabled" = false;
      "BrowserSignin" = 0;
      "DefaultBrowserSettingEnabled" = false;
      "DefaultSearchProviderEnabled" = true;
      "DefaultSearchProviderSearchURL" = "https://duckduckgo.com/?q={searchTerms}";
      "ExtensionInstallForcelist" = [
        "ddkjiahejlhfcafbddmgiahcphecmpfh" # uBlock Origin Lite
        "nngceckbapebfimnlniiiahkandclblb" # BitWarden
      ];
      "ImportBookmarks" = false;
      "PasswordManagerEnabled" = false;
      "SpellcheckEnabled" = true;
      "SpellcheckLanguage" = [
        "pt-BR"
        "en-US"
      ];
      "SyncDisabled" = true;
    };
  };
}
