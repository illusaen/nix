{
  modules.nixos = {
    host,
    lib,
    options,
    pkgs,
    sources,
    ...
  }: let
    agenixPackage = pkgs.callPackage "${sources.agenix.outPath}/pkgs/agenix.nix" {};
  in {
    imports = [
      "${sources.agenix.outPath}/modules/age.nix"
    ];

    config =
      {
        age.identityPaths = [host.privateKey];

        environment.systemPackages = [
          agenixPackage
          pkgs.age
        ];
      }
      // lib.optionalAttrs (options ? persist) {
        persist.files = [
          {
            file = host.privateKey;
            mode = "0600";
          }
        ];
      };
  };

  modules.darwin = {
    host,
    pkgs,
    sources,
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
}
