{
  inputs,
  lib,
  config,
  rootPath,
  ...
}: {
  config.flake-file.inputs.base16.url = "github:SenchoPens/base16.nix";
  config.fleet.base16.theme = rootPath + /resources/themes/tokyo-night-moon.yaml;

  options.fleet.base16 = lib.mkOption {
    type = lib.types.submodule {
      options = {
        scheme = lib.mkOption {
          type = lib.types.functionTo lib.types.raw;
          readOnly = true;
          description = "Computed base16/base24 scheme attributes from the given theme";
          default = pkgs:
            (pkgs.callPackage inputs.base16.lib {}).mkSchemeAttrs config.fleet.base16.theme;
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
      };
    };
  };
}
