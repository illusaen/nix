{rootPath, ...}: {
  flake.modules.darwin.steam.homebrew.cashs = ["steam"];

  flake.modules.nixos.steam = {
    pkgs,
    fleet,
    config,
    lib,
    ...
  }: {
    persistUser.directories = [".local/share/Steam"];

    programs.steam = {
      enable = true;
      package = pkgs.steam.override {
        extraPkgs = _pkgs': [_pkgs'.local.${fleet.theming.cursor.packageName}];
      };
    };

    environment.systemPackages = [
      (
        let
          id = "2819520";
        in
          pkgs.makeDesktopItem {
            name = "viking-rise";
            desktopName = "Viking Rise";
            comment = "Play Viking Rise through Steam";
            exec = "${lib.getExe config.programs.steam.package} steam://rungameid/${id}";
            icon = rootPath + /resources/icons/viking-rise-icon.png;
            categories = ["Game"];
          }
      )
    ];

    systemdAutostart = [{package = config.programs.steam.package;}];
  };
}
