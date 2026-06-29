{lib, ...}: let
  inherit (lib) mkOption;
  inherit (lib.types) attrsOf anything submodule str;
in {
  options.fleet = mkOption {
    type = submodule {
      options = {
        domain = mkOption {
          type = str;
          description = "Base domain for the fleet";
        };

        timeZone = mkOption {
          type = str;
          default = "CST";
          description = "Default timezone for the fleet";
        };

        moduleSettings = mkOption {
          type = attrsOf anything;
          default = {};
          description = "Fleet-level raw module settings defaults.";
        };
      };
    };
  };
  config.fleet = {
    domain = "lan";
    timeZone = "America/Chicago";
  };
}
