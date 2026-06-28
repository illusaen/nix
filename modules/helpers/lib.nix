{lib, ...}: {
  _module.args.helpers = let
    inherit (lib) mkOption optionalAttrs;
    inherit (lib.types) submodule str int package;
    mkStrOption = description:
      mkOption {
        type = str;
        inherit description;
      };
  in {
    inherit mkStrOption;

    mkThemeOption = {
      withSize ? false,
      withPkgs ? false,
    }:
      mkOption {
        type = submodule {
          options =
            {
              name = mkStrOption "Font family, found with fc-list";
              packageName = mkStrOption "Package name as attr key in pkgs";
            }
            // optionalAttrs withSize {
              size = mkOption {type = int;};
            }
            // optionalAttrs withPkgs {
              package = mkOption {type = package;};
            };
        };
      };

    removeAttrs' = lib.flip removeAttrs;
  };
}
