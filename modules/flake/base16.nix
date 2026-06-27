{
  inputs,
  lib,
  config,
  ...
}: {
  config.flake-file.inputs.base16.url = "github:SenchoPens/base16.nix";

  options.base16 = lib.mkOption {
    type = lib.types.submodule {
      options = {
        scheme = lib.mkOption {
          type = lib.types.functionTo lib.types.raw;
          readOnly = true;
          default = pkgs:
            (pkgs.callPackage inputs.base16.lib {}).mkSchemeAttrs config.fleet.theme;
        };
        colorScheme = lib.mkOption {
          type = lib.types.enum ["dark" "light"];
          default = "dark";
        };
      };
    };
  };
}
