{config, ...}: {
  fleet.hosts.odin = {
    system = "x86_64-linux";
    owner = "wendy";
  };

  debug = true;
  nixos.configurations.odin.module = {
    networking = {
      hostName = "odin";
      hostId = "abf835ae";
      domain = "lan";
    };
    nixpkgs.hostPlatform = "x86_64-linux";

    imports = with config.flake.modules.nixos;
      [
        base
        boot
        nvidia
        desktop-shell
        programs
        hardware
        theming
      ]
      ++ (with config.flake.modules.generic; [programs wendy]);
  };
}
