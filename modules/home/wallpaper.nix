{
  config,
  lib,
  helpers,
  pkgs,
  ...
}:
let
  cfg = config.modules.wallpaper;
in
{
  options.modules.wallpaper = {
    enable = helpers.mkTrueOption "wallpaper";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    home.activation = {
      "setWallpaper" = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        /usr/bin/osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"${../../resources/wallpaper-pastel-light.jpg}\""
      '';
    };
  };
}
