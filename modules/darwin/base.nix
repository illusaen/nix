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
    inputs.opnix.darwinModules.default
    ../system.nix
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
    ];

    programs._1password-gui.enable = true;

    homebrew.masApps = {
      "Microsoft Word" = 462054704;
      "NepTunes for iTunes Spotify" = 1006739057;
    };

    system.keyboard = {
      enableKeyMapping = true;
    };

    system.defaults = {
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
        AppleIconAppearanceTheme = "RegularDark";
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

    security.sudo.extraConfig = ''
      Defaults timestamp_timeout=30
    '';

    security.pam.services.sudo_local.watchIdAuth = true;
  };
}
