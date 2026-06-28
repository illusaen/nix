{config, ...}: {
  flake.modules.nixos.desktop-shell.imports = with config.flake.modules.nixos; [
    niri
    wallpaper
    nautilus
  ];

  flake.modules.darwin.desktop-shell.imports = with config.flake.modules.darwin; [
    wallpaper
  ];
}
