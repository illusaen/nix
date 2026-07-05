{
  lib,
  helpers,
  ...
}: let
  inherit (lib) mkOption types nameValuePair;
  inherit (helpers) mkThemeOption;
  mapListToAttrsWith = attrs: value: attrs |> map (v: nameValuePair v value) |> builtins.listToAttrs;
in {
  fleet.fonts = {
    sans = {
      name = "Inter";
      packageName = "inter";
    };
    mono = {
      name = "Monaspace Neon NF";
      packageName = "monaspace";
    };
    emoji = {
      name = "Noto Color Emoji";
      packageName = "noto-fonts-color-emoji";
    };
    icon = {
      name = "Material Symbols Outlined";
      packageName = "material-symbols";
    };
    sizes = {
      terminal = 12;
      applications = 12;
      desktop = 13;
    };
  };

  schema.fleet.options.fonts = mkOption {
    type = types.submodule {
      options = {
        sans = mkThemeOption {};
        mono = mkThemeOption {};
        emoji = mkThemeOption {};
        icon = mkThemeOption {};
        sizes = mkOption {
          type = types.submodule {
            options = mapListToAttrsWith ["terminal" "applications" "desktop"] (mkOption {type = types.int;});
          };
        };
      };
    };
  };
}
