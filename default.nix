let
  sources = import ./npins;
  fleetLib = import ./lib/fleet.nix {};
  serviceLib = import ./lib/services.nix {inherit fleetLib;};
  featureLib = import ./lib/features.nix {inherit fleetLib;};
  hostLib = import ./lib/hosts.nix {inherit featureLib fleetLib;};
  rawFleet = import ./fleet;
  fleet = fleetLib.assertValid (rawFleet // {hosts = serviceLib.routeHosts rawFleet;});
  hostFeatures = fleetLib.unique (builtins.concatLists (map (name: fleet.hosts.${name}.features or []) (builtins.attrNames fleet.hosts)));
  serviceFeatures = fleetLib.unique (map (name: fleet.services.${name}.feature or name) (builtins.attrNames fleet.services));
  declaredSecrets = builtins.attrNames (import ./secrets/secrets.nix);
  missingDeclaredSecrets = builtins.filter (name: !(builtins.pathExists (./secrets + "/${name}"))) declaredSecrets;
  serviceNames = builtins.attrNames rawFleet.services;
  serviceHosts = service:
    [service.primary] ++ (service.backups or []);
  expectedServiceSecrets = fleetLib.unique (
    builtins.concatLists (map (name: let
      service = rawFleet.services.${name};
      feature = service.feature or name;
    in
      if feature == "pihole"
      then map (hostName: "hosts/${hostName}/pihole-web-password.age") (serviceHosts service)
      else if feature == "navidrome"
      then ["shared/navidrome-env.age"]
      else [])
    serviceNames)
  );
  missingServiceSecretDeclarations =
    builtins.filter (name: !(builtins.elem name declaredSecrets)) expectedServiceSecrets;
  hostNames = builtins.attrNames fleet.hosts;
  hostsWithTag = tag:
    builtins.filter (name: builtins.elem tag (fleet.hosts.${name}.tags or [])) hostNames;
  selectHostNames = target:
    if target == "@all"
    then hostNames
    else if target == "@nixos"
    then builtins.attrNames (fleetLib.platformHosts "nixos" fleet.hosts)
    else if target == "@darwin"
    then builtins.attrNames (fleetLib.platformHosts "darwin" fleet.hosts)
    else if builtins.substring 0 1 target == "@"
    then hostsWithTag (builtins.substring 1 (builtins.stringLength target) target)
    else if builtins.hasAttr target fleet.hosts
    then [target]
    else throw "unknown deploy target '${target}'";
in {
  inherit featureLib fleet fleetLib hostLib rawFleet serviceLib sources;

  inherit (fleet) hosts;

  deploy = {
    inherit hostNames hostsWithTag selectHostNames;
    nixosHosts = fleetLib.platformHosts "nixos" fleet.hosts;
    darwinHosts = fleetLib.platformHosts "darwin" fleet.hosts;
    nixosHostNames = builtins.attrNames (fleetLib.platformHosts "nixos" fleet.hosts);
    darwinHostNames = builtins.attrNames (fleetLib.platformHosts "darwin" fleet.hosts);
  };

  debug = {
    secrets = {
      declared = declaredSecrets;
      missingFiles = missingDeclaredSecrets;
      expectedForServices = expectedServiceSecrets;
      missingServiceDeclarations = missingServiceSecretDeclarations;
    };

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
    featureClosure =
      featureLib.close ["nix-settings"]
      == ["nix-settings"]
      && builtins.elem "secrets" (featureLib.close ["base"]);
    hostFeaturesExist = featureLib.missingFeatures hostFeatures == [];
    hostFeaturesHavePlatformModules =
      builtins.all (
        name:
          featureLib.missingPlatformModules fleet.hosts.${name}.platform (fleet.hosts.${name}.features or [])
          == []
      )
      (builtins.attrNames fleet.hosts);
    serviceFeaturesExist = featureLib.missingFeatures serviceFeatures == [];
    serviceFeaturesHaveNixosModules = featureLib.missingPlatformModules "nixos" serviceFeatures == [];
    hostPublicKeysExist = builtins.all (name: builtins.pathExists fleet.hosts.${name}.publicKey) (builtins.attrNames fleet.hosts);
    serviceSecretsDeclared = missingServiceSecretDeclarations == [];
    servicePortsDoNotConflict = serviceLib.portConflicts rawFleet == [];
    deploySelectors =
      selectHostNames "odin"
      == ["odin"]
      && selectHostNames "@all" == ["huginn" "muninn" "odin"]
      && selectHostNames "@nixos" == ["huginn" "muninn" "odin"]
      && selectHostNames "@darwin" == []
      && selectHostNames "@server" == ["huginn" "muninn"];
  };
}
