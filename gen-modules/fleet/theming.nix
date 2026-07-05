{
  lib,
  helpers,
  ...
}: let
  inherit (helpers) mkThemeOption;
in {
  schema.fleet.options.theming = lib.mkOption {
    type = lib.types.submodule {
      options = {
        icon = mkThemeOption {};
        cursor = mkThemeOption {withSize = true;};
        gtk = mkThemeOption {};
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
      size = 32;
    };
    gtk = {
      name = "MacTahoe";
      packageName = "mactahoe-gtk-theme";
    };
  };
}
