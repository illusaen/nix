{config, ...}: {
  fleet.hosts.odin = {
  };

  nixos.configurations.odin.module = {
    networking = {
      hostName = "odin";
      hostId = "abf835ae";
      domain = "lan";
    };
    nixpkgs.hostPlatform = "x86_64-linux";

    imports = with config.flake.modules.nixos; [
      base
      boot
      nvidia
      desktop-shell
    ];
  };
}
