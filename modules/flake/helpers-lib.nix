{lib, ...}: {
  _module.args.helpers = let
    inherit (lib) mkOption optionalAttrs;
    inherit (lib.types) submodule str int package;
  in {
    mkThemeOption = {
      withSize ? false,
      withPkgs ? false,
    }:
      mkOption {
        type = submodule {
          options =
            {
              name = mkOption {
                type = str;
                description = "Name of theme/cursor/icon/font, i.e. package inter has font name Inter and package whitesur-gtk-theme has name WhiteSur";
              };
              packageName = mkOption {
                type = str;
                description = "Package name as attr key in pkgs";
              };
            }
            // optionalAttrs withSize {
              size = mkOption {
                type = int;
                description = "size of theme option";
              };
            }
            // optionalAttrs withPkgs {
              package = mkOption {
                type = package;
                description = "package in store";
              };
            };
        };
      };

    removeAttrs' = lib.flip removeAttrs;

    toGtkIni = lib.generators.toINI {
      mkKeyValue = key: value: let
        value' =
          if lib.isBool value
          then lib.boolToString value
          else toString value;
      in "${lib.escape ["="] key}=${value'}";
    };
  };
}
