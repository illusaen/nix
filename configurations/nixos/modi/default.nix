{
  inputs,
  config,
  lib,
  modulesPath,
  pkgs,
  vars,
  ...
}:
let
  inherit (vars) name fullName seedbox;
  inherit (seedbox)
    hostName
    ip
    gateway
    domain
    group
    hd
    ;
in
{
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
    "${toString modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    ./system.nix
  ];

  config.modules = {
    modi.enable = true;
    blocky.enable = true;
    jellyfin.enable = true;
    navidrome.enable = true;
    samba.enable = true;
    transmission.enable = true;
  };
}
