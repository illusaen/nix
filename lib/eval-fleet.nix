{
  featureLib,
  lib,
  serviceLib,
}: let
  evalFleet = fleetData:
    (lib.evalModules {
      modules = [
        ./fleet-options.nix
        {fleet = fleetData;}
      ];
    }).config.fleet;

  attachServices = evaluatedFleet:
    evaluatedFleet
    // {
      hosts =
        lib.mapAttrs (
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
        lib.mapAttrs (
          _hostName: host:
            host
            // {
              features = featureLib.featuresForHost host;
            }
        )
        evaluatedFleet.hosts;
    };
in {
  inherit evalFleet;

  resolveFleet = rawFleet:
    lib.pipe rawFleet [
      evalFleet
      attachServices
      attachFeatures
    ];
}
