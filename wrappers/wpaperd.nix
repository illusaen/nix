{
  wlib,
  lib,
  pkgs,
  config,
  ...
}: {
  imports = [
    wlib.modules.default
    ./service.nix
  ];

  options = {
    imageDirectory = lib.mkOption {type = lib.types.path;};
    monitors = lib.mkOption {
      type = lib.types.submodule {
        options = {
          main = lib.mkOption {type = lib.types.str;};
          secondary = lib.mkOption {type = lib.types.str;};
        };
      };
    };
  };

  config = {
    package = pkgs.wpaperd;
    service.enable = true;
    env.XDG_CONFIG_HOME = placeholder "out";
    constructFiles = {
      generatedConfig = {
        content = ''
          [default]
          duration = "15m"

          [default.transition.directional-wipe]

          [${builtins.toJSON config.monitors.main}]
          mode = "stretch"
          path = "${config.imageDirectory}"

          [${builtins.toJSON config.monitors.secondary}]
          mode = "center"
          path = "${config.imageDirectory}"
        '';
        relPath = "wpaperd/config.toml";
      };
    };
  };
}
