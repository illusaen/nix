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
  resolveFleet = evaluatedFleet: let
    servicesByHost = serviceLib.servicesByHost evaluatedFleet;
    hostsWithServices =
      nixpkgsLib.mapAttrs (
        hostName: host:
          host
          // {
            services = servicesByHost.${hostName};
          }
      )
      evaluatedFleet.hosts;
    featuresByHost = featureLib.featuresByHost hostsWithServices;
  in
    evaluatedFleet
    // {
      hosts =
        nixpkgsLib.mapAttrs (
          hostName: host:
            host
            // {
              inherit (host) services;
              features = featuresByHost.${hostName};
            }
        )
        hostsWithServices;
    };
  fleet = fleetLib.assertValid (resolveFleet typedFleet);
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
