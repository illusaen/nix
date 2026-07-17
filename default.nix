let
  sources = import ./npins;
  lib = import (sources.nixpkgs.outPath + "/lib");
  fleetLib = import ./lib/fleet.nix {inherit lib;};
  packageLib = import ./lib/packages.nix {inherit lib;};
  serviceLib = import ./lib/services.nix {
    inherit lib;
  };
  featureLib = import ./lib/features.nix {
    inherit sources lib;
  };
  hostLib = import ./lib/hosts.nix {
    inherit featureLib fleetLib packageLib serviceLib;
  };
  evalLib = import ./lib/eval-configurations.nix {
    inherit fleetLib hostLib sources lib;
  };
  typedFleet = (import ./lib/eval-fleet.nix {inherit lib;}) (import ./fleet);
  deployLib = import ./lib/deploy.nix {
    inherit fleet fleetLib;
  };
  fleet = fleetLib.assertValid (typedFleet // {hosts = serviceLib.routeHosts typedFleet;});
  checks = import ./tests/checks.nix {
    inherit deployLib featureLib fleet serviceLib typedFleet lib;
  };
in {
  inherit fleet sources checks;
  inherit (hostLib) mkHostModule;

  nixosConfigurations = evalLib.mkNixosConfigurations {inherit fleet;};
  darwinConfigurations = evalLib.mkDarwinConfigurations {inherit fleet;};

  deploy = deployLib;
  packageOverlay = packageLib.overlay;
}
