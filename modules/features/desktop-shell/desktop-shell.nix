{config, ...}: {
  flake.modules.nixos.desktop-shell.imports = with config.flake.modules.nixos; [
    niri
    display-manager
    wallpaper
    nautilus
    waybar
  ];

  flake.modules.darwin.desktop-shell.imports = with config.flake.modules.darwin; [
    wallpaper
  ];
}
