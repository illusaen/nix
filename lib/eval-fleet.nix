{
  featureLib,
  lib,
  serviceLib,
}: let
  attachHostRoutes = evaluatedFleet:
    evaluatedFleet
    // {
      hosts =
        lib.mapAttrs (
          hostName: host: let
            services = serviceLib.servicesForHost hostName evaluatedFleet.services;
          in
            host
            // {
              inherit services;
              features = featureLib.featuresForHost {inherit host services;};
            }
        )
        evaluatedFleet.hosts;
    };
in rec {
  evalFleet = fleetData:
    (lib.evalModules {
      modules = [
        ./fleet-options.nix
        {fleet = fleetData;}
      ];
    }).config.fleet;

  resolveFleet = rawFleet:
    lib.pipe rawFleet [
      evalFleet
      attachHostRoutes
    ];
}
