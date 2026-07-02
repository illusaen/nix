{inputs, ...}: {
  imports = [inputs.wrappers.flakeModules.wrappers];

  config = {
    flake-file.inputs.wrappers = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

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
