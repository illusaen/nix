{lib, ...}: let
  monitorType = lib.types.submodule {
    options = {
      desc = lib.mkOption {type = lib.types.str;};
      connector = lib.mkOption {type = lib.types.enum ["DP-2" "HDMI-A-2"];};
    };
  };
in {
  schema.fleet.options.monitors = lib.mkOption {
    type = lib.types.submodule ({config, ...}: {
      options = {
        data = lib.mkOption {type = lib.types.attrsOf monitorType;};
        desc = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          readOnly = true;
          default = lib.mapAttrs (_name: config: config.desc) config.data;
        };
        conn = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          readOnly = true;
          default = lib.mapAttrs (_name: config: config.connector) config.data;
        };
      };
    });
  };

  fleet.monitors.data = {
    main = {
      desc = "BOE Display 000000001";
      connector = "DP-2";
    };
    secondary = {
      desc = "LG Electronics LG ULTRAGEAR+ 508RMWVJR505";
      connector = "HDMI-A-2";
    };
  };

  flake.modules.nixos.monitors = {
    hardware.i2c.enable = true;
  };
}
