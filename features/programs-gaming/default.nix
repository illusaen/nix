_: {
  imports = [];

  modules.nixos = {
    config,
    fleet,
    lib,
    options,
    pkgs,
    ...
  }: let
    cursorPackage = pkgs.${fleet.theming.cursor.packageName} or null;
    vikingRiseDesktopItem = pkgs.makeDesktopItem {
      name = "viking-rise";
      desktopName = "Viking Rise";
      comment = "Play Viking Rise through Steam";
      exec = "${lib.getExe config.programs.steam.package} steam://rungameid/2819520";
      icon = ../../resources/icons/viking-rise-icon.png;
      categories = ["Game"];
    };
  in {
    programs.steam = {
      enable = true;
      package = lib.mkIf (cursorPackage != null) (pkgs.steam.override {
        extraPkgs = _pkgs': [cursorPackage];
      });
    };

    environment.systemPackages = [
      vikingRiseDesktopItem
    ];

    persistUser.directories = [
      ".local/share/Steam"
    ];

    systemdAutostart = lib.mkIf (options ? systemdAutostart) [
      {package = config.programs.steam.package;}
    ];
  };

  modules.darwin = _: {
    homebrew.casks = ["steam"];
  };
}
