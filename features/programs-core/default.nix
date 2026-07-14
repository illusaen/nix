_: {
  imports = [];

  modules.nixos = {
    config,
    fleet,
    lib,
    pkgs,
    sources,
    user,
    ...
  }: let
    userName = user.name or "wendy";
    firefoxAddonsOverlay = final: prev: let
      firefoxAddonsRoot = builtins.dirOf (builtins.dirOf sources."firefox-addons".outPath);
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
    firefoxGlobalExtensions = with pkgs.firefox-addons; [
      ublock-origin
      sponsorblock
      onepassword-password-manager
      vimium
      translate-web-pages
      sidebery
    ];
    firefoxExtensionSettings = builtins.listToAttrs (
      map (package:
        lib.nameValuePair package.addonId {
          installation_mode = "force_installed";
          install_url = "file://${package.outPath}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/${package.addonId}.xpi";
        })
      firefoxGlobalExtensions
    );
    firefoxFontSize = size: toString (builtins.floor (size * 4 / 3 + 0.5));
    firefoxConfigDir = "/home/${userName}/.config/mozilla/firefox";
    firefoxProfileDir = "${firefoxConfigDir}/default.default";
    firefoxIni = lib.generators.toINI {} {
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
    shimmer = sources.shimmer.outPath;
    optionalPackage = name:
      lib.optional (pkgs ? ${name}) pkgs.${name};
    onePasswordGuiPackage =
      pkgs._1password-gui-beta or pkgs._1password-gui;
    wrappedYtDlp =
      if pkgs ? yt-dlp
      then
        pkgs.writeShellApplication {
          name = "yt-dlp";
          text = ''
            exec ${pkgs.yt-dlp}/bin/yt-dlp -t aac --cookies-from-browser firefox "$@"
          '';
        }
      else null;
    autostartEntryType = lib.types.submodule ({config, ...}: {
      options = {
        package = lib.mkOption {type = lib.types.package;};
        name = lib.mkOption {
          type = lib.types.str;
          default = lib.getName config.package;
        };
        exec = lib.mkOption {
          type = lib.types.str;
          default = lib.getExe config.package;
        };
      };
    });
    mkAutostartService = entry: {
      wantedBy = ["graphical-session.target"];
      partOf = ["graphical-session.target"];
      after = ["graphical-session.target"];
      description = "Autostarts ${entry.name} on login";
      serviceConfig = {
        ExecStart = entry.exec;
        Restart = "on-failure";
      };
    };
  in {
    options.systemdAutostart = lib.mkOption {
      type = lib.types.listOf autostartEntryType;
      default = [];
    };

    config = {
      nixpkgs.overlays = [firefoxAddonsOverlay];

      environment.systemPackages =
        lib.optional (wrappedYtDlp != null) wrappedYtDlp
        ++ optionalPackage "ytmdesktop";

      programs = {
        firefox = {
          enable = true;
          languagePacks = [
            "en-US"
            "zh-CN"
          ];
          autoConfig =
            builtins.readFile ../../modules/features/programs/core/firefox/betterfox.js
            + ''
              pref("font.size.monospace.x-western", ${firefoxFontSize fleet.fonts.sizes.terminal});
              pref("font.size.variable.x-western", ${firefoxFontSize fleet.fonts.sizes.applications});
              pref("font.minimum-size.x-western", ${firefoxFontSize fleet.fonts.sizes.applications});
              pref("font.minimum-size.x-unicode", ${firefoxFontSize fleet.fonts.sizes.applications});
              pref("browser.display.use_document_fonts", 0);
            '';
          policies = {
            DisableTelemetry = true;
            DisplayMenuBar = "never";
            OfferToSaveLogins = false;
            Homepage = {
              URL = "http://google.com/";
              StartPage = "previous-session";
            };
            SearchEngines.Add = [
              {
                Name = "NixOS Packages";
                URLTemplate = "https://search.nixos.org/packages?type=packages&channel=unstable&query={searchTerms}";
                Method = "GET";
                IconURL = "https://wiki.nixos.org/nixos.png";
                Alias = "@np";
                Description = "NixOS packages";
              }
              {
                Name = "NixOS Options";
                URLTemplate = "https://search.nixos.org/options?type=options&channel=unstable&query={searchTerms}";
                Method = "GET";
                IconURL = "https://wiki.nixos.org/nixos.png";
                Alias = "@no";
                Description = "NixOS options";
              }
              {
                Name = "NixOS Wiki";
                URLTemplate = "https://wiki.nixos.org/w/index.php?search={searchTerms}";
                Method = "GET";
                IconURL = "https://wiki.nixos.org/nixos.png";
                Alias = "@nw";
                Description = "Official NixOS wiki";
              }
              {
                Name = "Noogle";
                URLTemplate = "https://noogle.dev/q/?term={searchTerms}";
                Method = "GET";
                IconURL = "https://wiki.nixos.org/nixos.png";
                Alias = "@noog";
                Description = "Wiki for nix functions";
              }
            ];
            ExtensionSettings = firefoxExtensionSettings;
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
        _1password.enable = pkgs ? _1password-cli;
        _1password-gui = lib.mkIf (pkgs ? _1password-gui) {
          enable = true;
          package = onePasswordGuiPackage;
          polkitPolicyOwners = [userName];
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
        ".config/1Password"
        ".config/mozilla/firefox"
        ".config/YouTube Music Desktop App"
      ];

      systemdAutostart =
        lib.optional (pkgs ? _1password-gui) {
          name = "one-password";
          package = onePasswordGuiPackage;
        }
        ++ lib.optional (pkgs ? ytmdesktop) {
          package = pkgs.ytmdesktop;
        };

      systemd.user.services =
        builtins.listToAttrs (map (entry: lib.nameValuePair entry.name (mkAutostartService entry)) config.systemdAutostart);

      systemd.tmpfiles.settings.firefox = {
        "${firefoxConfigDir}".d = {
          user = userName;
          group = "users";
          mode = "0700";
        };
        "${firefoxProfileDir}".d = {
          user = userName;
          group = "users";
          mode = "0700";
        };
        "${firefoxProfileDir}/chrome".d = {
          user = userName;
          group = "users";
          mode = "0700";
        };
        "${firefoxConfigDir}/profiles.ini"."f+" = {
          user = userName;
          group = "users";
          mode = "0644";
          argument = firefoxIni;
        };
        "${firefoxProfileDir}/chrome/shimmerChrome.css"."L+".argument = "${shimmer}/userChrome.css";
        "${firefoxProfileDir}/chrome/shimmerContent.css"."L+".argument = "${shimmer}/userContent.css";
        "${firefoxProfileDir}/chrome/userChrome.css"."L+".argument = toString (pkgs.writeText "firefox-userChrome.css" ''
          @import url("shimmerChrome.css");

          #TabsToolbar {
            display: none !important;
          }
        '');
        "${firefoxProfileDir}/chrome/userContent.css"."L+".argument = toString (pkgs.writeText "firefox-userContent.css" ''
          @import url("shimmerContent.css");
        '');
      };
    };
  };

  modules.darwin = _: {
    homebrew.casks = ["firefox"];
  };
}
