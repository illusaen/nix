{
  wlib,
  lib,
  config,
  ...
}: {
  imports = [
    wlib.wrapperModules.foot
    ./service.nix
  ];

  options = {
    font = lib.mkOption {
      type = lib.types.submodule {
        options = {
          name = lib.mkOption {type = lib.types.str;};
          size = lib.mkOption {type = lib.types.int;};
        };
      };
    };
    colors = lib.mkOption {
      type = lib.types.raw;
      readOnly = true;
    };
  };

  config.service = {
    enable = true;
    executable = "${config.wrapperPaths.placeholder} --server";
  };
  config.filesToExclude = [
    "share/applications/foot.desktop"
    "share/applications/foot-server.desktop"
  ];
  config.settings = let
    theme = "dark";
    inherit (config) colors font;
  in {
    main = {
      font = "${font.name}:size=${toString font.size}";
      initial-color-theme = theme;
      pad = "32x32";
    };
    scrollback.lines = 10000;
    "colors-${theme}" = {
      foreground = colors.base05;
      background = colors.base00;
      regular0 = colors.base00;
      regular1 = colors.base08;
      regular2 = colors.base0B;
      regular3 = colors.base0A;
      regular4 = colors.base0D;
      regular5 = colors.base0E;
      regular6 = colors.base0C;
      regular7 = colors.base05;
      bright0 = colors.base03;
      bright1 = colors.base08;
      bright2 = colors.base0B;
      bright3 = colors.base0A;
      bright4 = colors.base0D;
      bright5 = colors.base0E;
      bright6 = colors.base0C;
      bright7 = colors.base07;
      "16" = colors.base09;
      "17" = colors.base0F;
      "18" = colors.base01;
      "19" = colors.base02;
      "20" = colors.base04;
      "21" = colors.base06;
    };
  };
}
