{config, ...}: {
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
        desktop-shell
      ]
      ++ (with config.flake.modules.generic; [package-overlay]);
  };
}
