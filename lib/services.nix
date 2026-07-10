{fleetLib ? import ./fleet.nix {}}: let
  inherit (builtins) attrNames listToAttrs map;
  inherit (fleetLib) unique;

  serviceForHost = hostName: serviceName: service:
    if service.primary == hostName
    then [
      {
        name = serviceName;
        value = service // {role = "primary";};
      }
    ]
    else if builtins.elem hostName (service.backups or [])
    then [
      {
        name = serviceName;
        value = service // {role = "backup";};
      }
    ]
    else [];

  servicesForHost = hostName: services:
    listToAttrs (
      builtins.concatLists (
        map (serviceName: serviceForHost hostName serviceName services.${serviceName})
        (attrNames services)
      )
    );

  routedFeatureNames = routedServices:
    unique (map (name: routedServices.${name}.feature or name) (attrNames routedServices));

  routeHosts = fleet:
    builtins.mapAttrs (
      hostName: host: let
        services = servicesForHost hostName fleet.services;
      in
        host
        // {
          name = hostName;
          inherit services;
          features = unique ((host.features or []) ++ routedFeatureNames services);
        }
    )
    fleet.hosts;
in {
  inherit routeHosts routedFeatureNames servicesForHost;
}
