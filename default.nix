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
  evalFleet = import ./lib/eval-fleet.nix {lib = nixpkgsLib;};
  typedFleet = evalFleet (import ./fleet);
  deployLib = import ./lib/deploy.nix {
    inherit fleet fleetLib;
  };
  fleet = fleetLib.assertValid (typedFleet // {hosts = serviceLib.routeHosts typedFleet;});
  checks = import ./tests/checks.nix {
    inherit deployLib featureLib fleet serviceLib typedFleet;
    lib = nixpkgsLib;
  };
  libs = {
    inherit evalFleet evalLib featureLib fleetLib hostLib packageLib serviceLib deployLib;
    nixpkgs = nixpkgsLib;
  };
in {
  inherit fleet sources checks libs;

  nixosConfigurations = evalLib.mkNixosConfigurations {inherit fleet;};
  darwinConfigurations = evalLib.mkDarwinConfigurations {inherit fleet;};

  overlays = packageLib.overlay;
}
