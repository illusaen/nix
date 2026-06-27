{
  lib,
  rootPath,
  ...
}: let
  inherit (lib) mkOption;
  inherit (lib.types) submodule path str;
in {
  options.fleet = mkOption {
    type = submodule {
      options = {
        domain = mkOption {
          type = str;
          description = "Base domain for the environment";
        };

        timeZone = mkOption {
          type = str;
          default = "CST";
          description = "Default timezone for the environment";
        };

        theme = mkOption {
          type = path;
          description = "Base16/Base24 theme used";
        };
      };
    };
  };
  config.fleet = {
    domain = "lan";
    timeZone = "America/Chicago";
    theme = rootPath + /resources/themes/tokyo-night-moon.yaml;
  };
}
