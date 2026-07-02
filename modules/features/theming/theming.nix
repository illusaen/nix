{
  lib,
  helpers,
  config,
  ...
}: {
  schema.fleet.options.theming = lib.mkOption {
    type = lib.types.submodule {
      options = let
        inherit (helpers) mkThemeOption;
      in {
        icon = mkThemeOption {};
        cursor = mkThemeOption {withSize = true;};
      };
    };
  };

  fleet.theming = {
    icon = {
      name = "MacTahoe";
      packageName = "mactahoe-icon-theme";
    };
    cursor = {
      name = "MacTahoe-Cursors";
      packageName = "mactahoe-cursors";
      size = 28;
    };
  };

  flake.moduleImports.theming = ["gtk" "runtime-theming"];

  flake.modules.nixos.theming = {pkgs, ...}: let
    inherit (config.fleet.theming) icon cursor;
  in {
    environment.systemPackages = [pkgs.local.${icon.packageName} pkgs.local.${cursor.packageName}];
  };
}
