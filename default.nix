let
  sources = import ./npins;
  nixpkgsLib = import (sources.nixpkgs.outPath + "/lib");
  fleetLib = import ./lib/fleet.nix {lib = nixpkgsLib;};
  packageLib = import ./lib/packages.nix {lib = nixpkgsLib;};
  serviceLib = import ./lib/services.nix {
    lib = nixpkgsLib;
  };
  featureLib = import ./lib/features.nix {
    inherit sources;
    lib = nixpkgsLib;
  };
  hostLib = import ./lib/hosts.nix {
    inherit featureLib fleetLib packageLib serviceLib;
  };
  evalLib = import ./lib/eval-configurations.nix {
    inherit fleetLib hostLib sources;
    lib = nixpkgsLib;
  };
  evalFleetLib = import ./lib/eval-fleet.nix {
    inherit featureLib serviceLib;
    lib = nixpkgsLib;
  };
  inherit (evalFleetLib) evalFleet resolveFleet;
  rawFleet = import ./fleet;
  typedFleet = evalFleet rawFleet;
  fleet = fleetLib.assertValid (resolveFleet rawFleet);
  deployLib = import ./lib/deploy.nix {
    inherit fleet fleetLib;
  };
  libs = {
    inherit evalFleet evalLib featureLib fleetLib hostLib packageLib serviceLib deployLib resolveFleet;
    nixpkgs = nixpkgsLib;
  };
  checks = import ./tests/checks.nix {
    inherit fleet libs typedFleet;
    lib = nixpkgsLib;
  };
in {
  inherit fleet sources checks libs;

  nixosConfigurations = evalLib.mkNixosConfigurations {inherit fleet;};
  darwinConfigurations = evalLib.mkDarwinConfigurations {inherit fleet;};

  overlays = packageLib.overlay;
}
