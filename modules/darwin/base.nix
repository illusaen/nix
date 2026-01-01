# Base Darwin module - core configurations enabled by default
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.modules.base;
  feather = pkgs.stdenvNoCC.mkDerivation {
    name = "feather";
    src = pkgs.fetchFromGitHub {
      owner = "AT-UI";
      repo = "feather-font";
      rev = "2ac71612ee85b3d1e9e1248cec0a777234315253";
      sha256 = "sha256-W4CHvOEOYkhBtwfphuDIosQSOgEKcs+It9WPb2Au0jo=";
    };
    phases = [
      "installPhase"
    ];
    installPhase = ''
      mkdir -p $out/share/fonts/truetype
      cp -r $src/src/fonts/*.ttf $out/share/fonts/truetype/
    '';
  };
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

    environment.systemPackages = with pkgs; [
      antigravity
      google-chrome
      raycast
    ];

    programs._1password-gui.enable = true;

    fonts.packages = with pkgs; [
      monaspace
      nerd-fonts.monaspace
      nerd-fonts.symbols-only
      feather
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
