{inputs, ...}: {
  flake-file.inputs.agenix = {
    url = "github:ryantm/agenix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.nixos.secrets = {pkgs, ...}: {
    imports = [inputs.agenix.nixosModules.default];

    age = {
      identityPaths = ["/etc/ssh/host_ed25519"];
      secrets = {};
    };

    environment.systemPackages = [
      inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
      pkgs.age
    ];
  };
}
