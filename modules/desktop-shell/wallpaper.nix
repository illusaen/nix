{
  rootPath,
  config,
  lib,
  ...
}: {
  options.fleet.wallpaper = lib.mkOption {
    type = lib.types.submodule {
      options = {
        image = lib.mkOption {
          type = lib.types.path;
          default = rootPath + /resources/wallpapers/dark-silk.jpeg;
        };
        directory = lib.mkOption {
          type = lib.types.path;
          default = rootPath + /resources/wallpapers;
        };
      };
    };
  };

  config.flake.modules.nixos.wallpaper = {pkgs, ...}: {
    environment.systemPackages = [pkgs.local.wpaperd];
    systemd.packages = [pkgs.local.wpaperd];
    systemd.user.services.wpaperd.wantedBy = ["graphical-session.target"];
  };

  config.flake.modules.darwin.wallpaper = {
    system.activationScripts.setDesktopBackground = ''
      echo "Setting desktop background."
      osascript -e 'tell application "System Events" to tell every desktop to set picture to "${config.fleet.wallpaper.image}"'
    '';
  };

  config.flake.wrappers.wpaperd = {
    imports = [(rootPath + /wrappers/wpaperd.nix)];
    imageDirectory = config.fleet.wallpaper.directory;
    monitors = config.fleet.monitors.conn;
  };
}
