{
  inputs,
  lib,
  config,
  rootPath,
  ...
}: {
  fleet.themes = {
    default = "tokyo-night-moon";
    profiles = {
      tokyo-night-moon = {
        colorScheme = "dark";
        base16Theme = rootPath + /resources/themes/tokyo-night-moon.yaml;
      };
      catppuccin-latte = {
        colorScheme = "light";
        base16Theme = rootPath + /resources/themes/catppuccin-latte.yaml;
      };
    };
  };
  fleet.base16 = let
    defaultTheme = config.fleet.themes.profiles.${config.fleet.themes.default};
  in {
    theme = lib.mkDefault defaultTheme.base16Theme;
    colorScheme = lib.mkDefault defaultTheme.colorScheme;
  };

  schema.fleet.options.base16 = lib.mkOption {
    type = lib.types.submodule ({config, ...}: {
      options = {
        scheme = lib.mkOption {
          type = lib.types.functionTo lib.types.raw;
          readOnly = true;
          description = "Computed base16/base24 scheme attributes from the given theme";
          default = pkgs:
            (pkgs.callPackage inputs.base16.lib {}).mkSchemeAttrs config.theme;
        };
        theme = lib.mkOption {
          type = lib.types.path;
          description = "Base16/Base24 theme used";
        };
        colorScheme = lib.mkOption {
          type = lib.types.enum ["dark" "light"];
          default = "dark";
          description = "Dark or light theme";
        };
        isDark = lib.mkOption {
          type = lib.types.bool;
          readOnly = true;
          default = config.colorScheme == "dark";
        };
      };
    });
  };
  schema.fleet.options.themes = lib.mkOption {
    type = lib.types.submodule {
      options = {
        default = lib.mkOption {
          type = lib.types.str;
          description = "Default runtime theme profile.";
        };
        profiles = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                base16Theme = lib.mkOption {
                  type = lib.types.path;
                  description = "Base16/Base24 theme file for this runtime profile.";
                };
                colorScheme = lib.mkOption {
                  type = lib.types.enum ["dark" "light"];
                  description = "Dark or light appearance preference.";
                };
                wallpaper = lib.mkOption {
                  type = lib.types.nullOr lib.types.path;
                  default = null;
                  description = "Optional wallpaper override for this runtime profile.";
                };
              };
            }
          );
          description = "Runtime-selectable theme profiles.";
        };
      };
    };
  };
}
