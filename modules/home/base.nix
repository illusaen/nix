# Base Home Manager module - core configurations enabled by default
{
  config,
  lib,
  pkgs,
  inputs,
  outputs,
  ...
}:
let
  cfg = config.modules.base;
in
{
  # Imports must be at top level (not inside mkIf)
  imports = [
    inputs.opnix.homeManagerModules.default
  ];

  options.modules.base = {
    enable = lib.mkEnableOption "base home-manager configuration" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs = {
      overlays = builtins.attrValues outputs.overlays;
      config = {
        allowUnfree = true;
        allowUnfreePredicate = _: true;
      };
    };

    nix = {
      package = lib.mkDefault pkgs.nix;
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        warn-dirty = false;
      };
    };

    systemd.user.startServices = "sd-switch";

    programs = {
      home-manager.enable = true;
    };

    home.sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.cargo/bin"
    ];
  };
}
