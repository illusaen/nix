let
  sources = import ./npins;
  fleetLib = import ./lib/fleet.nix {};
  serviceLib = import ./lib/services.nix {inherit fleetLib;};
  featureLib = import ./lib/features.nix {inherit fleetLib;};
  rawFleet = import ./fleet;
  fleet = fleetLib.assertValid (rawFleet // {hosts = serviceLib.routeHosts rawFleet;});
in {
  inherit featureLib fleet fleetLib rawFleet serviceLib sources;

  inherit (fleet) hosts;

  deploy = {
    nixosHosts = fleetLib.platformHosts "nixos" fleet.hosts;
    darwinHosts = fleetLib.platformHosts "darwin" fleet.hosts;
    nixosHostNames = builtins.attrNames (fleetLib.platformHosts "nixos" fleet.hosts);
    darwinHostNames = builtins.attrNames (fleetLib.platformHosts "darwin" fleet.hosts);
  };

  debug = {
    routedServices = builtins.mapAttrs (_hostName: host:
      builtins.mapAttrs (_serviceName: service: {
        inherit (service) feature port protocol role;
        inherit (service) primary;
        backups = service.backups or [];
      })
      host.services)
    fleet.hosts;
  };

  checks = {
    fleet = fleetLib.validate rawFleet == [];
    routedServices =
      (serviceLib.servicesForHost "odin" rawFleet.services).navidrome.role
      == "primary"
      && (serviceLib.servicesForHost "huginn" rawFleet.services).pihole.role == "primary"
      && (serviceLib.servicesForHost "muninn" rawFleet.services).pihole.role == "backup";
    featureClosure = featureLib.close ["nix-settings"] == ["nix-settings"];
  };
}
