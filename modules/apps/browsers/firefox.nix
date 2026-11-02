# modules/apps/browsers/firefox.nix --- https://www.mozilla.org/firefox/
#
# Oh Firefox, gateway to the interwebs, devourer of ram. Give onto me your
# infinite knowledge and shelter me from ads, but bless my $HOME with
# directories nobody needs and live long enough to turn into Chrome.
#
# This used to wrap LibreWolf. Upstream Firefox brings DRM and a smaller
# distance to Mozilla's security releases, so the hardening LibreWolf shipped
# by default is spelled out here instead: telemetry, studies and feedback off
# through enterprise policies, sponsored content off through prefs, uBlock
# Origin preinstalled. RFP is deliberately left disabled in favor of FPP.
{
  self,
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with self.lib; let
  cfg = config.modules.apps.browsers.firefox;
in {
  options.modules.apps.browsers.firefox = with types; {
    enable = mkBoolOpt false;
    profileName = mkOpt str config.user.name;

    settings =
      mkOpt'
      (attrsOf (oneOf [
        bool
        int
        str
      ]))
      {}
      ''
        Firefox preferences to set in <filename>user.js</filename>
      '';
    extraConfig = mkOpt' lines "" ''
      Extra lines to add to <filename>user.js</filename>
    '';

    userChrome = mkOpt' lines "" "CSS Styles for Firefox's interface";
    userContent = mkOpt' lines "" "Global CSS Styles for websites";

    extensions =
      mkOpt' (attrsOf attrs) {
        # LibreWolf installed this for us; AMO is the source either way.
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/uBlock0@raymondhill.net/latest.xpi";
          installation_mode = "normal_installed";
        };
      } ''
        ExtensionSettings policies, by extension ID.
      '';
  };

  config = mkIf cfg.enable (mkMerge [
    {
      user.packages = with pkgs; [
        gabutdm
        (mkLauncherEntry "Firefox (Private)" {
          description = "Open a private Firefox window";
          icon = "firefox";
          exec = "firefox --private-window";
          categories = ["Network"];
        })
        (mkLauncherEntry "Firefox (Alt)" {
          description = "Open the alt Firefox profile";
          icon = "firefox";
          exec = "firefox -P alt";
          categories = ["Network"];
        })
      ];

      # Treat Firefox as our default PDF reader
      xdg.mime = {
        defaultApplications."application/pdf" = "firefox.desktop";
        addedAssociations."application/pdf" = "firefox.desktop";
      };

      programs.firefox = {
        enable = true;

        # System-wide /etc/firefox/policies/policies.json. This is the part
        # LibreWolf enforced with lockPref: it can't be flipped back from
        # about:config or an extension.
        policies = {
          DisableTelemetry = true;
          DisableFirefoxStudies = true;
          DisableFeedbackCommands = true;
          DontCheckDefaultBrowser = true;
          ExtensionSettings = cfg.extensions;
        };

        autoConfig = let
          prefs = {
            # The xdg-desktop-portal doesn't propagate the correct clipboard to
            # file/save dialg windows, so disable it and use the native file picker.
            "widget.use-xdg-desktop-portal.file-picker" = 0;
            # Allow svgs to take on theme colors
            "svg.context-properties.content.enabled" = true;
            # Pressing TAB from address bar shouldn't cycle through buttons before
            # switching focus back to the webppage. Most of those buttons have
            # dedicated shortcuts, so I don't need this level of tabstop granularity.
            "browser.toolbars.keyboard_navigation" = false;

            # Seriously. Stop popping up on every damn page. If I want it translated,
            # I know where to find gtranslate/deepl/whatever!
            "browser.translations.automaticallyPopup" = false;
            # Enable userContent.css and userChrome.css for our theme modules
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            # Allow my local dashboard to live and be loaded
            "security.sandbox.content.read_path_whitelist" = "${config.magi.configDir}/firefox/";
            # Do not check if Firefox is the default browser
            "browser.shell.checkDefaultBrowser" = false;
            # Disable the "new tab page" feature and show a blank tab instead
            # https://wiki.mozilla.org/Privacy/Reviews/New_Tab
            # https://support.mozilla.org/en-US/kb/new-tab-page-show-hide-and-customize-top-sites#w_how-do-i-turn-off-the-new-tab-page
            "browser.newtabpage.enabled" = false;
            "browser.newtab.preload" = false;
            # Reduce search engine noise in the urlbar's completion window. The
            # shortcuts and suggestions will still work, but Firefox won't clutter
            # its UI with reminders that they exist.
            "browser.urlbar.shortcuts.bookmarks" = false;
            "browser.urlbar.shortcuts.history" = false;
            "browser.urlbar.shortcuts.tabs" = false;
            "browser.urlbar.showSearchSuggestionsFirst" = false;
            # Since FF 113, you must press TAB twice to cycle through urlbar
            # suggestions. This disables that.
            "browser.urlbar.resultMenu.keyboardAccessible" = false;
            # Show whole URL in address bar
            "browser.urlbar.trimURLs" = false;
            # Disable some not so useful functionality.
            "browser.disableResetPrompt" = true; # "Looks like you haven't started Firefox in a while."
            "reader.parse-on-load.enabled" = false; # "reader view"

            # https://support.mozilla.org/en-US/kb/extension-recommendations
            "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
            "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
            # Reduce File IO / SSD abuse
            # Otherwise, Firefox bombards the HD with writes. Not so nice for SSDs.
            # This forces it to write every 30 minutes, rather than 15 seconds.
            # Must be an int; a string here is silently rejected as a type mismatch.
            "browser.sessionstore.interval" = 1800000;
            # Disable battery API
            # https://developer.mozilla.org/en-US/docs/Web/API/BatteryManager
            # https://bugzilla.mozilla.org/show_bug.cgi?id=1313580
            "dom.battery.enabled" = false;
            # Disable "beacon" asynchronous HTTP transfers (used for analytics)
            # https://developer.mozilla.org/en-US/docs/Web/API/navigator/sendBeacon
            "beacon.enabled" = false;
            # Don't try to guess domain names when entering an invalid domain name in URL bar
            # http://www-archive.mozilla.org/docs/end-user/domain-guessing.html
            "browser.fixup.alternate.enabled" = false;
            # Disable health reports (basically more telemetry). LibreWolf locked
            # the rest of the telemetry, normandy and crash reporter prefs, so
            # replicate that here.
            # https://support.mozilla.org/en-US/kb/firefox-health-report-understand-your-browser-perf
            "datareporting.healthreport.service.enabled" = false;
            "datareporting.healthreport.uploadEnabled" = false;
            "datareporting.policy.dataSubmissionEnabled" = false;
            "toolkit.telemetry.unified" = false;
            "toolkit.telemetry.enabled" = false;
            "toolkit.telemetry.server" = "data:,";
            "toolkit.telemetry.archive.enabled" = false;
            "toolkit.telemetry.newProfilePing.enabled" = false;
            "toolkit.telemetry.shutdownPingSender.enabled" = false;
            "toolkit.telemetry.updatePing.enabled" = false;
            "toolkit.telemetry.bhrPing.enabled" = false;
            "toolkit.telemetry.firstShutdownPing.enabled" = false;
            "toolkit.coverage.opt-out" = true;
            "toolkit.coverage.endpoint.base" = "";
            "identity.fxaccounts.telemetry.clientInfoPing.enabled" = false;
            "browser.newtabpage.activity-stream.feeds.telemetry" = false;
            "browser.newtabpage.activity-stream.telemetry" = false;
            "browser.ping-centre.telemetry" = false;
            # Also keep crash reports and add-on recommendations off.
            "breakpad.reportURL" = "";
            "browser.crashReports.unsubmittedCheck.enabled" = false;
            "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;
            "browser.discovery.enabled" = false;
            "extensions.htmlaboutaddons.recommendations.enabled" = false;
            # No sponsored or trending clutter in the urlbar/new tab.
            "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
            "browser.urlbar.suggest.quicksuggest.sponsored" = false;
            "browser.urlbar.sponsoredTopSites" = false;
            "browser.urlbar.trending.featureGate" = false;
            "browser.newtabpage.activity-stream.showSponsored" = false;
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
            # No VPN/Focus/Pin/"More from Mozilla" promos.
            "browser.vpn_promo.enabled" = false;
            "browser.promo.focus.enabled" = false;
            "browser.preferences.moreFromMozilla" = false;
            # LibreWolf blocks the AI features through policies; keep them off.
            "browser.ml.chat.enabled" = false;
            "browser.ml.linkPreview.enabled" = false;
            "browser.tabs.groups.smart.enabled" = false;
            # Disable Form autofill.
            # https://wiki.mozilla.org/Firefox/Features/Form_Autofill
            "extensions.formautofill.available" = "off";
            "extensions.formautofill.creditCards.available" = false;
            # FPP eats the same target list as RFP, with the one target I care
            # about carved out. RFP pins prefers-color-scheme to light and Mozilla
            # won't let that target be excluded (bug 1732114).
            "privacy.fingerprintingProtection" = true;
            "privacy.fingerprintingProtection.overrides" = "+AllTargets,-CSSPrefersColorScheme";
            # 0 = dark, regardless of what GTK or the browser theme claims.
            "layout.css.prefers-color-scheme.content-override" = 0;
          };
        in
          concatStrings (
            mapAttrsToList
            (name: value: ''
              defaultPref("${name}", ${builtins.toJSON value});
            '')
            prefs
          );
      };

      home.file = let
        # MOZ_LEGACY_PROFILES=1 (nixpkgs' wrapper) keeps Firefox on ~/.mozilla.
        localDir = ".mozilla/firefox";
        userjs = mkIf (cfg.settings != {} || cfg.extraConfig != "") {
          text = ''
            ${concatStrings (
              mapAttrsToList (name: value: ''
                user_pref("${name}", ${builtins.toJSON value});
              '')
              cfg.settings
            )}
            ${cfg.extraConfig}
          '';
        };
        profileFiles = profile: {
          "${localDir}/${cfg.profileName}.${profile}/user.js" = userjs;
          "${localDir}/${cfg.profileName}.${profile}/chrome/userChrome.css".text = ''
            @import url("file://${config.magi.configDir}/firefox/userChrome.css");
            ${optionalString (cfg.userChrome != "") cfg.userChrome}
          '';
          "${localDir}/${cfg.profileName}.${profile}/chrome/userContent.css".text = cfg.userContent;
        };
      in
        {
          # Use fixed profile names so it can be targeted in themes and scripts
          "${localDir}/profiles.ini".text = ''
            [General]
            StartWithLastProfile=1
            Version=2

            [Profile0]
            Name=default
            IsRelative=1
            Path=${cfg.profileName}.default
            Default=1

            [Profile1]
            Name=alt
            IsRelative=1
            Path=${cfg.profileName}.alt
          '';
        }
        // profileFiles "default"
        // profileFiles "alt";
    }
  ]);
}
