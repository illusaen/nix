{config, ...}: {
  flake.wrappers.swaylock = {
    wlib,
    pkgs,
    ...
  }: let
    scheme = config.fleet.base16.scheme pkgs;
    inherit (config.fleet.fonts) sans;
    wallpaper = config.fleet.wallpaper.image;
  in {
    imports = [wlib.wrapperModules.swaylock];
    settings = with scheme; let
      inside = base00;
      ring = base0E;
      text = base05;
      positive = base0B;
      negative = base08;
      transparent = "${base00}00";
    in {
      daemonize = true;
      ignore-empty-password = true;
      show-failed-attempts = true;
      indicator-idle-visible = true;
      indicator-radius = 128;
      indicator-thickness = 8;
      scaling = "center";
      font = sans;
      font-size = 24;
      image = wallpaper;

      color = inside;
      inside-color = transparent;
      inside-clear-color = inside;
      inside-caps-lock-color = inside;
      inside-ver-color = inside;
      inside-wrong-color = inside;
      key-hl-color = positive;
      layout-bg-color = inside;
      layout-border-color = ring;
      layout-text-color = text;
      ring-color = ring;
      ring-clear-color = negative;
      ring-caps-lock-color = ring;
      ring-ver-color = positive;
      ring-wrong-color = negative;
      separator-color = transparent;
      text-color = text;
      text-clear-color = text;
      text-caps-lock-color = text;
      text-ver-color = text;
      text-wrong-color = text;
    };
  };
}
