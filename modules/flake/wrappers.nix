{
  inputs,
  self,
  ...
}: {
  flake-file.inputs.wrappers = {
    url = "github:BirdeeHub/nix-wrapper-modules";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
  };
  imports = [inputs.wrappers.flakeModules.wrappers];
  flake.nixosModules = builtins.mapAttrs (_: v: v.install) self.wrappers;
  perSystem = {pkgs, ...}: {wrappers.pkgs = pkgs;};
}
