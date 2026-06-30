{
  flake.moduleImports.generic.programs = ["one-password" "zed"];
  flake.moduleImports.nixos.programs = ["firefox" "one-password" "autostart" "codex" "images" "zathura" "steam"];
  flake.moduleImports.darwin.programs = ["firefox" "codex" "images" "steam"];
}
