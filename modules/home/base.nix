# Base Home Manager module - core configurations enabled by default
{
  config,
  lib,
  pkgs,
  inputs,
  outputs,
  helpers,
  vars,
  ...
}:
let
  cfg = config.modules.base;
in
{
  imports = [
    inputs.opnix.homeManagerModules.default
  ];

  options.modules.base = {
    enable = helpers.mkTrueOption "base home-manager configuration";
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

    home.sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.cargo/bin"
    ];

    systemd.user.startServices = "sd-switch";

    programs = {
      home-manager.enable = true;
      onepassword-secrets = {
        enable = true;
        tokenFile = "/etc/opnix-token";

        secrets = {
          sshPrivateKey = {
            reference = "op://Service/SSH-Key-Nix/private key?ssh-format=openssh";
            path = ".ssh/id_rsa";
            mode = "0600";
          };
          sshPublicKey = {
            reference = "op://Service/SSH-Key-Nix/public key";
            path = ".ssh/id_rsa.pub";
            mode = "0600";
          };
        };
      };
    };
  };
}
