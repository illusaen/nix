{config, ...}: let
  shared = with config.flake.modules.generic; [
    nix-settings
    shell-utils
  ];
in {
  flake.modules.nixos.base.imports = with config.flake.modules.nixos;
    [
      base-configuration
      base16
      state-version
    ]
    ++ shared;

  flake.modules.darwin.base.imports = with config.flake.modules.darwin;
    [
      state-version
    ]
    ++ shared;
}
