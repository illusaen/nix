{
  self,
  inputs,
  lib,
  ...
}:

let
  autowire = import ./lib/autowire.nix { inherit lib; };
  root = ./.;
  vars = import ./lib/vars.nix;
in
{
  perSystem =
    { pkgs, system, ... }:
    {
      formatter = pkgs.nixfmt-rfc-style;
    };

  flake = {
    overlays = import ./overlays { inherit inputs; };

    nixosModules = autowire.discoverModules { dir = root + /modules/nixos; };
    darwinModules = autowire.discoverModules { dir = root + /modules/darwin; };
    homeManagerModules = autowire.discoverModules { dir = root + /modules/home; };

    nixosConfigurations = autowire.discoverNixosConfigurations {
      dir = root + /configurations/nixos;
      inherit inputs;
      outputs = self;
      nixosModules = self.nixosModules;
      specialArgs = { inherit vars; };
    };

    darwinConfigurations = autowire.discoverDarwinConfigurations {
      dir = root + /configurations/darwin;
      inherit inputs;
      outputs = self;
      darwinModules = self.darwinModules;
      specialArgs = { inherit vars; };
    };

    homeConfigurations = autowire.discoverHomeConfigurations {
      dir = root + /users;
      darwinDir = root + /configurations/darwin;
      inherit inputs;
      outputs = self;
      homeModules = self.homeManagerModules;
      extraSpecialArgs = {
        inherit vars;
        helpers = import ./lib/helpers.nix { inherit lib; };
      };
    };
  };
}
