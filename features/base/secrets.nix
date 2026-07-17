{sources, ...}: {
  modules.generic = {
    pkgs,
    host,
    ...
  }: let
    agenixPackage = pkgs.callPackage "${sources.agenix.outPath}/pkgs/agenix.nix" {};
  in {
    imports = [
      "${sources.agenix.outPath}/modules/age.nix"
    ];

    age.identityPaths = [host.privateKey];
    environment.systemPackages = [
      agenixPackage
      pkgs.age
    ];
  };

  modules.nixos = {
    host,
    lib,
    options,
    ...
  }:
    lib.mkIf (options ? persist) {
      persist.files = [
        {
          file = host.privateKey;
          mode = "0640";
          group = "wheel";
        }
      ];
    };
}
