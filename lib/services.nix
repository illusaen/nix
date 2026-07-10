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

  normalizeHost = hostName: host: let
    preservation =
      if host.preservation.enable or false
      then
        {
          rootSnapshot = "zroot/local/root@blank";
          homeSnapshot = "zroot/local/home@blank";
          persistMount = "/persist";
        }
        // host.preservation
      else host.preservation or {enable = false;};
  in
    host
    // {
      name = hostName;
      privateKey = host.privateKey or "/etc/ssh/ssh_host_ed25519_key";
      publicKey = host.publicKey or (../secrets/hosts + "/${hostName}/host_ed25519.pub");
      inherit preservation;
    };

  routeHosts = fleet:
    builtins.mapAttrs (
      hostName: host: let
        normalizedHost = normalizeHost hostName host;
        services = servicesForHost hostName fleet.services;
      in
        normalizedHost
        // {
          inherit services;
          features = unique ((normalizedHost.features or []) ++ routedFeatureNames services);
        }
    )
    fleet.hosts;
in {
  inherit normalizeHost routeHosts routedFeatureNames servicesForHost;
}
