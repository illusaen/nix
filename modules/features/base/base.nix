{
  flake.moduleImports.base = [
    "nix-settings"
    "shell-utils"
    "package-overlay"
    "fonts"
    "lix"
    "state-version"
    "security"
    "secrets"
    "autostart"
    "bat"
    "zsh"
    "defaults"
    "tailscale"
  ];
}
