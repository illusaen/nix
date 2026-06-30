{
  flake.moduleImports.nixos.desktop-shell = [
    "niri"
    "display-manager"
    "wallpaper"
    "nautilus"
    "waybar"
    "misc-scripts"
    "fuzzel"
  ];

  flake.moduleImports.darwin.desktop-shell = [
    "wallpaper"
  ];

  flake.modules.nixos.desktop-shell = {};
  flake.modules.darwin.desktop-shell = {};
}
