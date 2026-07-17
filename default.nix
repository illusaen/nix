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
  rawFleet = import ./fleet;
  attachServices = evaluatedFleet:
    evaluatedFleet
    // {
      hosts =
        nixpkgsLib.mapAttrs (
          hostName: host:
            host
            // {
              services = serviceLib.servicesForHost hostName evaluatedFleet.services;
            }
        )
        evaluatedFleet.hosts;
    };
  attachFeatures = evaluatedFleet:
    evaluatedFleet
    // {
      hosts =
        nixpkgsLib.mapAttrs (
          _hostName: host:
            host
            // {
              features = featureLib.featuresForHost host;
            }
        )
        evaluatedFleet.hosts;
    };
  resolveFleet = rawFleet:
    nixpkgsLib.pipe rawFleet [
      evalFleet
      attachServices
      attachFeatures
    ];
  typedFleet = evalFleet rawFleet;
  fleet = fleetLib.assertValid (resolveFleet rawFleet);
  deployLib = import ./lib/deploy.nix {
    inherit fleet fleetLib;
  };
  checks = import ./tests/checks.nix {
    inherit deployLib featureLib fleet serviceLib typedFleet;
    lib = nixpkgsLib;
  };
  libs = {
    inherit evalFleet evalLib featureLib fleetLib hostLib packageLib serviceLib deployLib resolveFleet;
    nixpkgs = nixpkgsLib;
  };
in {
  inherit fleet sources checks libs;

  nixosConfigurations = evalLib.mkNixosConfigurations {inherit fleet;};
  darwinConfigurations = evalLib.mkDarwinConfigurations {inherit fleet;};

  overlays = packageLib.overlay;
}
