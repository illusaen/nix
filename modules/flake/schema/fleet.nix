{lib, ...}: let
  inherit (lib) mkOption;
  inherit (lib.types) submodule str;
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
      };
    };
  };
  config.fleet = {
    domain = "lan";
    timeZone = "America/Chicago";
  };
}
