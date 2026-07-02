{
  inputs,
  self,
  ...
}: {
  imports = [inputs.wrappers.flakeModules.wrappers];

  config = {
    flake-file.inputs.wrappers = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    flake.nixosModules = builtins.mapAttrs (_: v: v.install) self.wrappers;
    perSystem = {pkgs, ...}: {
      wrappers = {
        inherit pkgs;
        packages = {
          noctalia-wrapped = true;
        };
      };
    };
  };
}
