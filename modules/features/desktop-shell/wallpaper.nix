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

  flake.modules.darwin.wallpaper = {fleet, ...}: {
    system.activationScripts.setDesktopBackground = ''
      echo "Setting desktop background."
      osascript -e 'tell application "System Events" to tell every desktop to set picture to "${fleet.wallpaper.image}"'
    '';
  };
}
