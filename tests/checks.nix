{
  deployLib,
  featureLib,
  fleet,
  lib,
  serviceLib,
  typedFleet,
}: let
  inherit (lib) pipe;

  testResults = (import ./fleet.nix) // featureLib.tests;

  hostFeatures = pipe fleet.hosts [
    builtins.attrNames
    (map (name: fleet.hosts.${name}.features))
    builtins.concatLists
    lib.unique
  ];

  serviceFeatures = pipe fleet.services [
    builtins.attrNames
    (map (name: fleet.services.${name}.feature))
    lib.unique
  ];

  secretDeclarations = import ../secrets/secrets.nix;
  declaredSecrets = builtins.attrNames secretDeclarations;
  serviceSecretRequirements = featureLib.serviceSecretRequirementsFor typedFleet.services;
  expectedServiceSecrets = pipe serviceSecretRequirements [
    (map (requirement: requirement.secret))
    lib.unique
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
in
  testResults
  // {
    featureClosure =
      featureLib.close ["base"]
      == ["base"];
    hostFeaturesExist = featureLib.missingFeatures hostFeatures == [];
    hostFeaturesHavePlatformModules =
      builtins.all (
        name:
          featureLib.missingPlatformModules fleet.hosts.${name}.platform (fleet.hosts.${name}.features or [])
          == []
      )
      (builtins.attrNames fleet.hosts);
    serviceFeaturesExist = featureLib.missingFeatures serviceFeatures == [];
    routedServiceFeaturesHavePlatformModules = serviceFeaturePlatformModuleErrors == [];
    hostPublicKeysExist = builtins.all (name: builtins.pathExists fleet.hosts.${name}.publicKey) (builtins.attrNames fleet.hosts);
    serviceSecretsDeclared = missingServiceSecretDeclarations == [];
    serviceSecretRecipientsCoverRoutedHosts = missingServiceSecretRecipients == [];
    servicePortsDoNotConflict = serviceLib.portConflicts typedFleet == [];
    inherit themeProfilesValid;
    deploySelectors =
      deployLib.selectHostNames "odin"
      == ["odin"]
      && deployLib.selectHostNames "@all" == ["huginn" "muninn" "odin"]
      && deployLib.selectHostNames "@nixos" == ["huginn" "muninn" "odin"]
      && deployLib.selectHostNames "@darwin" == []
      && deployLib.selectHostNames "@server" == ["huginn" "muninn"];
  }
