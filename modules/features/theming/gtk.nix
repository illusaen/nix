{
  helpers,
  config,
  lib,
  ...
}: {
  options.fleet.theming.gtk = helpers.mkThemeOption {};

  config.fleet.theming = let
    inherit (config.fleet.base16) colorScheme;
  in {
    gtk = {
      name = "MacTahoe-${lib.toSentenceCase colorScheme}";
      packageName = "mactahoe-gtk-theme";
    };
  };
}
