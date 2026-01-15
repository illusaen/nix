{
  self,
  inputs,
  lib,
  ...
}:

let
  vars = import ./lib/vars.nix;
  autowire = import ./lib/autowire.nix {
    inherit lib vars;
  };
  helpers = import ./lib/helpers.nix { inherit lib; };
  root = ./.;
in
{
  perSystem =
    { pkgs, system, ... }:
    {
      formatter = pkgs.nixfmt;
      packages.sd = self.outputs.nixosConfigurations.modi.config.system.build.sdImage;
    };

  flake = {
    overlays = autowire.discoverOverlays {
      dir = root + /overlays;
      inherit inputs;
    };

    sharedSystemModules = autowire.discoverModules { dir = root + /modules/system; };
    nixosModules = autowire.discoverModules { dir = root + /modules/nixos; };
    darwinModules = autowire.discoverModules { dir = root + /modules/darwin; };
    homeManagerModules = autowire.discoverModules { dir = root + /modules/home; };

    nixosConfigurations = autowire.discoverNixosConfigurations {
      dir = root + /configurations/nixos;
      inherit inputs;
      outputs = self;
      nixosModules = self.nixosModules // self.sharedSystemModules;
      specialArgs = { inherit vars helpers; };
    };

    darwinConfigurations = autowire.discoverDarwinConfigurations {
      dir = root + /configurations/darwin;
      inherit inputs;
      outputs = self;
      darwinModules = self.darwinModules // self.sharedSystemModules;
      homeModules = self.homeManagerModules;
      specialArgs = { inherit vars helpers; };
    };

    # homeConfigurations = autowire.discoverHomeConfigurations {
    #   dir = root + /users;
    #   darwinDir = root + /configurations/darwin;
    #   inherit inputs;
    #   outputs = self;
    #   homeModules = self.homeManagerModules;
    #   extraSpecialArgs = {
    #     inherit vars helpers;
    #   };
    # };
  };
}
