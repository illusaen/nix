# Base NixOS module - core configurations enabled by default
{
  config,
  lib,
  inputs,
  helpers,
  ...
}:
let
  cfg = config.modules.base;
in
{
  # Imports must be at top level (not inside mkIf)
  imports = [
    inputs.opnix.nixosModules.default
    ../system.nix
  ];

  options.modules.base = {
    enable = helpers.mkTrueOption "base nixos configuration";
  };

  config = lib.mkIf cfg.enable {
    nix.extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
}
