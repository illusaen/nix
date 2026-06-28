{inputs, ...} @ top: let
  flakeConfig = top.config;
in {
  flake-file.inputs.firefox-addons = {
    url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  flake.modules.darwin.firefox.homebrew.casks = ["firefox"];

  flake.modules.nixos.firefox = {
    pkgs,
    config,
    lib,
    ...
  }: {
    options.programs.firefox.globalExtensions = lib.mkOption {
      type = lib.types.listOf (
        lib.types.oneOf [
          lib.types.package
          (lib.types.submodule {
            options = {
              package = lib.mkOption {
                type = lib.types.package;
              };
              settings = lib.mkOption {
                type = lib.types.attrsOf (pkgs.formats.json {}).type;
                default = {};
                description = "Json formatted options for this extension.";
              };
            };
          })
        ]
      );
      default = [];
    };

    config.nixpkgs.overlays = [inputs.firefox-addons.overlays.default];
    config.xdg.mime.defaultApplications = let
      application = "firefox.desktop";
      mimeTypes = [
        "text/html"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "x-scheme-handler/about"
      ];
    in
      lib.genAttrs mimeTypes (_: application);
    config.programs.firefox = {
      enable = true;
      languagePacks = [
        "en-US"
        "zh-CN"
      ];
      globalExtensions = with pkgs.firefox-addons; [
        ublock-origin
        sponsorblock
        onepassword-password-manager
        vimium
        translate-web-pages
      ];
      autoConfig = let
        convertFontSize = size: toString (builtins.floor ((size * 4.0 / 3.0) + 0.5));
        inherit (flakeConfig.fleet.fonts.sizes) terminal applications;
        terminalFontSize = convertFontSize terminal;
        applicationFontSize = convertFontSize applications;
      in
        builtins.readFile ./betterfox.js
        + ''
          pref("font.size.monospace.x-western", ${terminalFontSize});
          pref("font.size.variable.x-western", ${applicationFontSize});
          pref("font.minimum-size.x-western", ${applicationFontSize});
          pref("font.minimum-size.x-unicode", ${applicationFontSize});
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
        ExtensionSettings = lib.pipe config.programs.firefox.globalExtensions [
          (builtins.filter (elem: (elem.package or elem) ? addonId))
          (map (
            elem: let
              package = elem.package or elem;
            in
              lib.nameValuePair package.addonId (
                {
                  installation_mode = "force_installed";
                  install_url = "file://${package.outPath}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/${package.addonId}.xpi";
                }
                // (elem.settings or {})
              )
          ))
          lib.listToAttrs
        ];
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

        # Privacy
        "privacy.userContext.enabled" = true;
        "extensions.webcompat-reporter.enabled" = false;
        "browser.ping-centre.telemetry" = false;
        "browser.urlbar.eventTelemetry.enabled" = false;

        "extensions.pocket.enabled" = false;
        "extensions.abuseReport.enabled" = false;
        "extensions.formautofill.creditCards.enabled" = false;
        "identity.fxaccounts.toolbar.enabled" = false;
        "browser.contentblocking.report.lockwise.enabled" = false;

        # Disable annoying web features
        "dom.push.enabled" = false;
        "dom.push.connection.enabled" = false;
        "dom.battery.enabled" = false;
        "dom.private-attribution.submission.enabled" = false;

        "sidebar.revamp" = true;
        "sidebar.verticalTabs" = true;
        "sidebar.position_start" = false;
      };
    };
  };
}
