let
  sources = import ./npins;
  nixpkgsLib = import (sources.nixpkgs.outPath + "/lib");
  fleetLib = import ./lib/fleet.nix {lib = nixpkgsLib;};
  packageLib = import ./lib/packages.nix {
    lib = nixpkgsLib;
  };
  serviceLib = import ./lib/services.nix {
    lib = nixpkgsLib;
  };
  featureLib = import ./lib/features.nix {
    inherit sources;
    lib = nixpkgsLib;
  };
  hostLib = import ./lib/hosts.nix {
    inherit featureLib fleetLib packageLib serviceLib;
    lib = nixpkgsLib;
  };
  evalLib = import ./lib/eval-configurations.nix {
    inherit featureLib fleetLib hostLib sources;
    lib = nixpkgsLib;
  };
  evalFleet = import ./lib/eval-fleet.nix {lib = nixpkgsLib;};
  rawFleet = import ./fleet;
  typedFleet = evalFleet rawFleet;
  fleet = fleetLib.assertValid (typedFleet // {hosts = serviceLib.routeHosts typedFleet;});
  deployLib = import ./lib/deploy.nix {
    inherit fleet fleetLib;
    lib = nixpkgsLib;
  };
  checks = import ./tests/checks.nix {
    inherit deployLib featureLib fleet serviceLib typedFleet;
    lib = nixpkgsLib;
  };
in {
  inherit fleet sources checks;
  inherit (hostLib) mkHostModule;

  nixosConfigurations = evalLib.mkNixosConfigurations {inherit fleet;};
  darwinConfigurations = evalLib.mkDarwinConfigurations {inherit fleet;};

  deploy = deployLib;
  packageOverlay = packageLib.overlay;
}
