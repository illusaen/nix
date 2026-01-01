# Base Darwin module - core configurations enabled by default
{
  config,
  lib,
  pkgs,
  inputs,
  outputs,
  pkgs-unstable,
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
    enable = lib.mkEnableOption "base darwin configuration" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    # Preserve existing nixbld GID
    ids.gids.nixbld = 350;

    environment.systemPackages = [
      pkgs.antigravity
      pkgs.google-chrome
      inputs.opnix.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    fonts.packages = [
      pkgs.monaspace
      pkgs.nerd-fonts.monaspace
      pkgs.nerd-fonts.symbols-only
    ];

    system.keyboard = {
      enableKeyMapping = true;
    };

    system.defaults = {
      menuExtraClock = {
        ShowDayOfWeek = true;
        ShowDayOfMonth = true;
      };

      finder = {
        AppleShowAllExtensions = true;
        FXEnableExtensionChangeWarning = false;
        ShowStatusBar = true;
        ShowPathbar = true;
      };

      SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;

      CustomUserPreferences.NSGlobalDomain = {
        AppleInterfaceStyle = "Light";
        AppleShowAllExtensions = true;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
      };

      CustomUserPreferences = {
        "com.apple.desktopservices".DSDontWriteNetworkStores = true;
        "com.apple.desktopservices".DSDontWriteUSBStores = true;
      };
    };

    nix.extraOptions = ''
      experimental-features = nix-command flakes
      extra-platforms = aarch64-darwin x86_64-darwin
    '';

    security.sudo.extraConfig = ''
      Defaults timestamp_timeout=30
    '';
  };
}
