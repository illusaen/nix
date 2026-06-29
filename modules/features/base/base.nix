{
  flake.moduleImports.generic.base = [
    "nix-settings"
    "shell-utils"
    "package-overlay"
    "fonts"
  ];

  flake.moduleImports.nixos.base = [
    "state-version"
    "fonts"
    "security"
    "zsh"
    "defaults"
  ];

  flake.moduleImports.darwin.base = [
    "state-version"
    "zsh"
  ];

  flake.modules.nixos.base = {};
  flake.modules.darwin.base = {};
}
