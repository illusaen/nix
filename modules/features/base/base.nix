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
    "tailscale"
  ];

  flake.moduleImports.darwin.base = [
    "state-version"
    "tailscale"
    "zsh"
  ];
}
