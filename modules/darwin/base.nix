# Base Darwin module - core configurations enabled by default
{
  config,
  lib,
  pkgs,
  inputs,
  helpers,
  ...
}:
let
  cfg = config.modules.base;
in
{
  # Imports must be at top level (not inside mkIf)
  imports = [
    ../system
  ];

  options.modules.base = {
    enable = helpers.mkTrueOption "base darwin configuration";
  };

  config = lib.mkIf cfg.enable {
    # Preserve existing nixbld GID
    ids.gids.nixbld = 350;

    environment.systemPackages = with pkgs; [
      antigravity
      google-chrome
      raycast
      iterm2
      audacity
      yt-dlp
      jellyfin
    ];

    programs._1password-gui.enable = true;

    homebrew = {
      masApps = {
        "Microsoft Word" = 462054704;
        "NepTunes for iTunes Spotify" = 1006739057;
      };
    };

    system.activationScripts.chmodOpnix = {
      text = ''
        echo "chmodding opnix-token"
        if [ -f "/etc/opnix-token" ]; then
            chmod 644 /etc/opnix-token
        fi
      '';
    };

    system.keyboard = {
      enableKeyMapping = true;
    };

    system.defaults = {
      dock = {
        wvous-bl-corner = 5;
        wvous-br-corner = 11;
        largesize = lib.mkDefault 72;
        magnification = true;
        minimize-to-application = true;
        orientation = "left";
        show-recents = false;
        static-only = true;
      };

      menuExtraClock = {
        ShowDayOfWeek = true;
        ShowDayOfMonth = true;
        ShowAMPM = true;
        ShowDate = 1;
        ShowSeconds = true;
      };

      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        FXDefaultSearchScope = "SCcf";
        FXEnableExtensionChangeWarning = false;
        FXPreferredViewStyle = "clmv";
        NewWindowTarget = "Home";
        ShowStatusBar = true;
        ShowPathbar = true;
        _FXEnableColumnAutoSizing = true;
        _FXSortFoldersFirst = true;
      };

      SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;

      NSGlobalDomain = {
        AppleIconAppearanceTheme = "ClearAutomatic";
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        AppleShowScrollBars = "Automatic";
        NSDocumentSaveNewDocumentsToCloud = false;
      };

      CustomUserPreferences = {
        "com.apple.desktopservices".DSDontWriteNetworkStores = true;
        "com.apple.desktopservices".DSDontWriteUSBStores = true;
      };
    };

    security.pam.services.sudo_local.watchIdAuth = true;
  };
}
