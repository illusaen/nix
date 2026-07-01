{inputs, ...}: {
  flake-file.inputs.agenix = {
    url = "github:ryantm/agenix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.nixos.secrets = {
    pkgs,
    host,
    ...
  }: {
    imports = [inputs.agenix.nixosModules.default];

    age.identityPaths = [host.privateKey];

    environment.systemPackages = [
      inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
      pkgs.age
    ];

    persist.files = [
      {
        file = host.privateKey;
        mode = "0600";
      }
    ];
  };
}
