{
  lib,
  helpers,
  config,
  ...
}: {
  options.fleet.theming = lib.mkOption {
    type = lib.types.submodule {
      options = let
        inherit (helpers) mkThemeOption;
      in {
        icon = mkThemeOption {};
        cursor = mkThemeOption {withSize = true;};
      };
    };
  };

  config.fleet.theming = let
    inherit (config.fleet.base16) isDark colorScheme;
  in {
    icon = {
      name = "MacTahoe-${colorScheme}";
      packageName = "mactahoe-icon-theme";
    };
    cursor = let
      suffix =
        if isDark
        then "-dark"
        else "";
    in {
      name = "MacTahoe${suffix} Cursors";
      packageName = "mactahoe-cursors";
      size = 28;
    };
  };

  config.flake.modules.nixos.theming = {pkgs, ...}: let inherit (config.fleet.theming) icon cursor; in {environment.systemPackages = [pkgs.local.${icon.packageName} pkgs.local.${cursor.packageName}];};
}
