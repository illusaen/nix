{lib, ...}: let
  monitorData = {
    main = {
      desc = "BOE Display 000000001";
      connector = "DP-2";
    };
    secondary = {
      desc = "LG Electronics LG ULTRAGEAR+ 508RMWVJR505";
      connector = "HDMI-A-2";
    };
  };

  monitorType = lib.types.enum (monitorData |> builtins.attrValues |> builtins.catAttrs "connector");
in {
  flake.moduleOptions.generic.monitors = {
    main = lib.mkOption {
      type = monitorType;
      description = "Main monitor connector";
      default = monitorData.main.connector;
    };
    secondary = lib.mkOption {
      type = lib.types.nullOr monitorType;
      description = "Secondary monitor connector";
      default = monitorData.secondary.connector;
    };
  };

  # this is needed because monitor option declarations are under `generic` scope
  # options won't be loaded unless there's also a generic concrete module
  flake.modules.generic.monitors = {};

  flake.modules.nixos.monitors = {
    hardware.i2c.enable = true;
  };

  fleet.groups.i2c = {
    isPosix = true;
    members = ["system-access"];
  };
}
