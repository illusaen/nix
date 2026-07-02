{
  flake.moduleImports.base = [
    "nix-settings"
    "shell-utils"
    "package-overlay"
    "lix"
    "state-version"
    "security"
    "secrets"
    "bat"
    "zsh"
    "defaults"
    "tailscale"
    "networking"
  ];
}
