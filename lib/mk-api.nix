{inputs}: let
  nixpkgsLib = inputs.nixpkgs.lib;
  fleetLib = import ./fleet.nix {lib = nixpkgsLib;};
  packageLib = import ./packages.nix {lib = nixpkgsLib;};
  serviceLib = import ./services.nix {
    inherit fleetLib;
    lib = nixpkgsLib;
  };
  featureLib = import ./features.nix {
    inherit inputs;
    lib = nixpkgsLib;
  };
  hostLib = import ./hosts.nix {
    inherit featureLib fleetLib packageLib serviceLib;
  };
  evalLib = import ./eval-configurations.nix {
    inherit fleetLib hostLib inputs;
  };
  evalFleetLib = import ./eval-fleet.nix {
    inherit featureLib serviceLib;
    lib = nixpkgsLib;
  };
  inherit (evalFleetLib) evalFleet resolveFleet;
  rawFleet = import ../fleet;
  fleet = fleetLib.assertValid (resolveFleet rawFleet);
  deployLib = import ./deploy.nix {
    inherit fleet fleetLib;
  };
  apiLib = {
    inherit deployLib evalFleet evalLib featureLib fleetLib hostLib resolveFleet serviceLib;
  };
  checks = import ../tests/checks.nix {
    inherit fleet;
    inherit (apiLib) deployLib evalFleet featureLib fleetLib resolveFleet serviceLib;
    lib = nixpkgsLib;
  };
in {
  inherit fleet checks;

  lib = apiLib;

  nixosConfigurations = evalLib.mkNixosConfigurations {inherit fleet;};
  darwinConfigurations = evalLib.mkDarwinConfigurations {inherit fleet;};

  inherit (packageLib) overlay;
}
