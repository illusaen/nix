{
  lib,
  config,
  ...
}: let
  monitorType = lib.types.submodule {
    options = {
      desc = lib.mkOption {type = lib.types.str;};
      connector = lib.mkOption {type = lib.types.enum ["DP-2" "HDMI-A-2"];};
    };
  };
in {
  options.fleet.monitors = lib.mkOption {
    type = lib.types.submodule {
      options = {
        data = lib.mkOption {type = lib.types.attrsOf monitorType;};
        desc = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          readOnly = true;
          default = lib.mapAttrs (_name: config: config.desc) config.fleet.monitors.data;
        };
        conn = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          readOnly = true;
          default = lib.mapAttrs (_name: config: config.connector) config.fleet.monitors.data;
        };
      };
    };
  };

  config.fleet.monitors.data = {
    main = {
      desc = "BOE Display 000000001";
      connector = "DP-2";
    };
    secondary = {
      desc = "LG Electronics LG ULTRAGEAR+ 508RMWVJR505";
      connector = "HDMI-A-2";
    };
  };

  config.flake.modules.nixos.monitors = {
    hardware.i2c.enable = true;
  };
}
