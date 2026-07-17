let
  sources = import ./npins;
  nixpkgsLib = import (sources.nixpkgs.outPath + "/lib");
  fleetLib = import ./lib/fleet.nix {lib = nixpkgsLib;};
  packageLib = import ./lib/packages.nix {
    lib = nixpkgsLib;
  };
  serviceLib = import ./lib/services.nix {
    lib = nixpkgsLib;
  };
  featureLib = import ./lib/features.nix {
    lib = nixpkgsLib;
  };
  hostLib = import ./lib/hosts.nix {
    inherit featureLib fleetLib packageLib;
    lib = nixpkgsLib;
  };
  evalLib = import ./lib/eval-configurations.nix {
    inherit featureLib fleetLib hostLib sources;
    lib = nixpkgsLib;
  };
  unitTests = (import ./tests/fleet.nix) // featureLib.tests;
  evalFleet = import ./lib/eval-fleet.nix {lib = nixpkgsLib;};
  rawFleet = import ./fleet;
  typedFleet = evalFleet rawFleet;
  fleet = fleetLib.assertValid (typedFleet // {hosts = serviceLib.routeHosts typedFleet;});
  inherit (nixpkgsLib) pipe;
  deployLib = import ./lib/deploy.nix {
    inherit fleet fleetLib;
    lib = nixpkgsLib;
  };
  hostFeatures = pipe fleet.hosts [
    builtins.attrNames
    (map (name: fleet.hosts.${name}.features))
    builtins.concatLists
    nixpkgsLib.unique
  ];
  serviceFeatures = pipe fleet.services [
    builtins.attrNames
    (map (name: fleet.services.${name}.feature))
    nixpkgsLib.unique
  ];
  declaredSecrets = builtins.attrNames (import ./secrets/secrets.nix);
  secretDeclarations = import ./secrets/secrets.nix;
  missingDeclaredSecrets = builtins.filter (name: !(builtins.pathExists (./secrets + "/${name}"))) declaredSecrets;
  serviceSecretRequirements = featureLib.serviceSecretRequirementsFor typedFleet.services;
  expectedServiceSecrets = pipe serviceSecretRequirements [
    (map (requirement: requirement.secret))
    nixpkgsLib.unique
  ];
  missingServiceSecretDeclarations =
    builtins.filter (name: !(builtins.elem name declaredSecrets)) expectedServiceSecrets;
  hostPublicKey = hostName:
    builtins.replaceStrings ["\n"] [""] (builtins.readFile fleet.hosts.${hostName}.publicKey);
  missingServiceSecretRecipients =
    builtins.filter (
      requirement:
        !(builtins.hasAttr requirement.secret secretDeclarations)
        || !(builtins.elem (hostPublicKey requirement.hostName) secretDeclarations.${requirement.secret}.publicKeys)
    )
    serviceSecretRequirements;
  serviceRoutingErrors = serviceLib.routingErrors typedFleet fleet;
  serviceFeaturePlatformModuleErrors =
    featureLib.serviceFeaturePlatformModuleErrors typedFleet.hosts typedFleet.services;
  themeNames = builtins.attrNames (fleet.themes.profiles or {});
  themeProfilesValid =
    builtins.hasAttr fleet.themes.default fleet.themes.profiles
    && builtins.all (
      name: let
        profile = fleet.themes.profiles.${name};
      in
        builtins.pathExists profile.base16Theme
        && (profile.wallpaper == null || builtins.pathExists profile.wallpaper)
        && (profile.colorScheme == "dark" || profile.colorScheme == "light")
    )
    themeNames;
in {
  inherit evalFleet evalLib featureLib fleet fleetLib hostLib nixpkgsLib packageLib rawFleet serviceLib sources typedFleet unitTests;

  inherit (fleet) hosts;

  deploy = deployLib;

  debug = {
    secrets = {
      declared = declaredSecrets;
      missingFiles = missingDeclaredSecrets;
      expectedForServices = expectedServiceSecrets;
      missingServiceDeclarations = missingServiceSecretDeclarations;
      missingServiceRecipients = missingServiceSecretRecipients;
    };

    routedServices = builtins.mapAttrs (_hostName: host:
      builtins.mapAttrs (_serviceName: service: {
        inherit (service) feature port protocol role;
        inherit (service) primary;
        backups = service.backups or [];
      })
      host.services)
    fleet.hosts;

    inherit serviceRoutingErrors;
  };

  checks = {
    fleet = fleetLib.validate typedFleet == [];
    routedServices =
      (serviceLib.servicesForHost "huginn" typedFleet.services).navidrome.role
      == "primary"
      && (serviceLib.servicesForHost "huginn" typedFleet.services).pihole.role == "primary"
      && (serviceLib.servicesForHost "muninn" typedFleet.services).pihole.role == "backup";
    featureClosure =
      featureLib.close ["base"]
      == ["base" "shell-utils"]
      && builtins.length featureLib.features.base.modules.nixos == 9
      && builtins.length featureLib.features.base.modules.darwin == 6;
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
    routedServiceFeaturesHavePlatformModules = serviceFeaturePlatformModuleErrors == [];
    hostPublicKeysExist = builtins.all (name: builtins.pathExists fleet.hosts.${name}.publicKey) (builtins.attrNames fleet.hosts);
    serviceSecretsDeclared = missingServiceSecretDeclarations == [];
    serviceSecretRecipientsCoverRoutedHosts = missingServiceSecretRecipients == [];
    serviceRoutingComplete = serviceRoutingErrors == [];
    servicePortsDoNotConflict = serviceLib.portConflicts typedFleet == [];
    localPackagesExist =
      packageLib.packageNames
      == [
        "mactahoe-cursors"
        "mactahoe-gtk-theme"
        "mactahoe-icon-theme"
        "misc-scripts"
        "niri-scripts"
      ];
    inherit themeProfilesValid;
    deploySelectors =
      deployLib.selectHostNames "odin"
      == ["odin"]
      && deployLib.selectHostNames "@all" == ["huginn" "muninn" "odin"]
      && deployLib.selectHostNames "@nixos" == ["huginn" "muninn" "odin"]
      && deployLib.selectHostNames "@darwin" == []
      && deployLib.selectHostNames "@server" == ["huginn" "muninn"];
    unitTests = builtins.all (name: unitTests.${name} == true) (builtins.attrNames unitTests);
  };
}
