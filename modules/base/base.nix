{config, ...}: let
  shared = with config.flake.modules.generic; [
    nix-settings
    shell-utils
    package-overlay
    fonts
  ];
in {
  flake.modules.nixos.base.imports = with config.flake.modules.nixos;
    [
      state-version
      fonts
      security
      networking
      zsh
    ]
    ++ shared;

  flake.modules.darwin.base.imports = with config.flake.modules.darwin;
    [
      state-version
      zsh
    ]
    ++ shared;
}
