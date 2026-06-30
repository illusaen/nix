{
  rootPath,
  lib,
  ...
}: {
  schema.fleet.options.wallpaper = lib.mkOption {
    type = lib.types.submodule {
      options = {
        image = lib.mkOption {
          type = lib.types.path;
          default = rootPath + /resources/wallpapers/dark-silk.jpeg;
          description = "default wallpaper used";
        };
        directory = lib.mkOption {
          type = lib.types.path;
          default = rootPath + /resources/wallpapers;
          description = "directory containing all wallpapers";
        };
      };
    };
  };

  flake.modules.nixos.wallpaper = {pkgs, ...}: {
    environment.systemPackages = [pkgs.local.wpaperd];
    systemd.packages = [pkgs.local.wpaperd];
    systemd.user.services.wpaperd.wantedBy = ["graphical-session.target"];
  };

  flake.modules.darwin.wallpaper = {fleet, ...}: {
    system.activationScripts.setDesktopBackground = ''
      echo "Setting desktop background."
      osascript -e 'tell application "System Events" to tell every desktop to set picture to "${fleet.wallpaper.image}"'
    '';
  };

  flake.fleetWrappers.wpaperd = {fleet, ...}: {
    imports = [(rootPath + /wrappers/wpaperd.nix)];
    imageDirectory = fleet.wallpaper.directory;
    monitors = fleet.monitors.conn;
  };
}
