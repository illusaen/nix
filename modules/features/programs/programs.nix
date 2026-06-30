{
  flake.moduleImports.generic.programs = ["one-password" "zed" "meld"];
  flake.moduleImports.nixos.programs = ["firefox" "one-password" "autostart" "codex" "images" "zathura" "steam" "ytmdesktop" "bambu-studio" "llama-cpp"];
  flake.moduleImports.darwin.programs = ["firefox" "codex" "images" "steam" "bambu-studio"];
}
