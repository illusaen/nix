{
  flake.moduleImports.nixos.desktop-shell = [
    "niri"
    "display-manager"
    "nautilus"
    "misc-scripts"
    "noctalia"
  ];

  flake.moduleImports.darwin.desktop-shell = [
    "wallpaper"
  ];
}
