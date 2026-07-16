{
  modules.generic = {
    user,
    lib,
    pkgs,
    sources,
    ...
  }: {
    hjem.users.${user.name}.xdg.config.files = let
      ff = "mozilla/firefox";
      chrome = "${ff}/default.default/chrome";
      shimmer = sources.shimmer.outPath;
      firefoxConfig = import ./config.nix {inherit pkgs;};
    in {
      "${ff}/profiles.ini".text = lib.generators.toINI {} {
        General = {
          StartWithLastProfile = 1;
          Version = 2;
        };
        Profile0 = {
          Name = "default";
          IsRelative = 1;
          Path = "default.default";
          Default = 1;
        };
      };
      "${chrome}/shimmerChrome.css".source = "${shimmer}/userChrome.css";
      "${chrome}/shimmerContent.css".source = "${shimmer}/userContent.css";
      "${chrome}/userChrome.css".source = pkgs.writeText "firefox-userChrome.css" (
        ''
          @import url("shimmerChrome.css");
        ''
        + firefoxConfig.userChrome
      );
      "${chrome}/userContent.css".source = pkgs.writeText "firefox-userContent.css" (
        ''
          @import url("shimmerContent.css");
        ''
        + firefoxConfig.userContent
      );
    };
  };

  modules.nixos = {
    fleet,
    lib,
    pkgs,
    sources,
    ...
  }: let
    firefoxAddonsOverlay = final: prev: let
      firefoxAddonsRoot = dirOf (dirOf sources."firefox-addons".outPath);
    in {
      firefox-addons = final.callPackage sources."firefox-addons".outPath {
        buildMozillaXpiAddon = let
          libMozilla = import (firefoxAddonsRoot + "/lib/mozilla.nix") {inherit (prev) lib;};
        in
          libMozilla.mkBuildMozillaXpiAddon {
            inherit (final) fetchurl stdenv;
          };
      };
    };

    firefoxConfig = import ./config.nix {inherit pkgs;};
    inherit (firefoxConfig) extensions searchEngines;
  in {
    nixpkgs.overlays = [firefoxAddonsOverlay];

    programs = {
      firefox = {
        enable = true;
        languagePacks = [
          "en-US"
          "zh-CN"
        ];
        autoConfig =
          builtins.readFile ./betterfox.js
          + (let
            fontSize = size: toString (builtins.floor (size * 4 / 3 + 0.5));
          in ''
            pref("font.size.monospace.x-western", ${fontSize fleet.fonts.sizes.terminal});
            pref("font.size.variable.x-western", ${fontSize fleet.fonts.sizes.applications});
            pref("font.minimum-size.x-western", ${fontSize fleet.fonts.sizes.applications});
            pref("font.minimum-size.x-unicode", ${fontSize fleet.fonts.sizes.applications});
            pref("browser.display.use_document_fonts", 0);
          '');
        policies = {
          DisableTelemetry = true;
          DisplayMenuBar = "never";
          OfferToSaveLogins = false;
          Homepage = {
            URL = "http://google.com/";
            StartPage = "previous-session";
          };
          SearchEngines.Add = searchEngines;
          ExtensionSettings = builtins.listToAttrs (
            map (package:
              lib.nameValuePair package.addonId {
                installation_mode = "force_installed";
                install_url = "file://${package.outPath}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/${package.addonId}.xpi";
              })
            extensions
          );
        };
        preferences = {
          "browser.ctrlTab.sortByRecentlyUsed" = false;
          "devtools.chrome.enabled" = true;
          "gfx.webrender.all" = true;
          "widget.dmabuf.force-enabled" = true;
          "media.av1.enabled" = true;
          "media.ffmpeg.vaapi.enabled" = true;
          "media.rdd-ffmpeg.enabled" = true;
          "media.rdd-vpx.enabled" = true;
          "media.rdd-process.enabled" = true;
          "browser.tabs.drawInTitlebar" = true;
          "browser.uidensity" = 0;
          "svg.context-properties.content.enabled" = true;
          "widget.gtk.rounded-bottom-corners.enabled" = true;
          "privacy.userContext.enabled" = true;
          "extensions.webcompat-reporter.enabled" = false;
          "browser.ping-centre.telemetry" = false;
          "browser.urlbar.eventTelemetry.enabled" = false;
          "extensions.pocket.enabled" = false;
          "extensions.abuseReport.enabled" = false;
          "extensions.formautofill.creditCards.enabled" = false;
          "identity.fxaccounts.toolbar.enabled" = false;
          "browser.contentblocking.report.lockwise.enabled" = false;
          "dom.push.enabled" = false;
          "dom.push.connection.enabled" = false;
          "dom.battery.enabled" = false;
          "dom.private-attribution.submission.enabled" = false;
          "reader.parse-on-load.enabled" = false;
          "shimmer.remove-winctr-buttons" = true;
          "shimmer.remove-firefox-view-button" = true;
        };
      };
    };

    xdg.mime.defaultApplications = let
      browser = "firefox.desktop";
    in {
      "text/html" = browser;
      "x-scheme-handler/http" = browser;
      "x-scheme-handler/https" = browser;
      "x-scheme-handler/about" = browser;
    };

    persistUser.directories = [
      ".config/mozilla/firefox"
    ];
  };

  modules.darwin = {
    homebrew.casks = ["firefox"];
  };
}
