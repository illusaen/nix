{
  flake.moduleImports.generic.programs = ["one-password" "zed"];
  flake.moduleImports.nixos.programs = ["firefox" "one-password" "autostart" "codex" "images"];
  flake.moduleImports.darwin.programs = ["firefox" "codex" "images"];

  flake.modules.generic.programs = {};
  flake.modules.nixos.programs = {};
  flake.modules.darwin.programs = {};
}
