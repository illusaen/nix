{fleetLib ? import ./fleet.nix {}}: let
  inherit (builtins) attrNames concatLists filter hasAttr listToAttrs map readDir;
  inherit (fleetLib) unique;

  featureRoot = ../features;

  featureNames =
    filter (name: (readDir featureRoot).${name} == "directory")
    (attrNames (readDir featureRoot));

  callFeature = feature:
    if builtins.isFunction feature
    then feature {}
    else feature;

  loadFeatureFile = path: callFeature (import path);

  featureImportEntries = feature:
    filter builtins.isString (feature.imports or []);

  localImportEntries = feature:
    filter (entry: !builtins.isString entry) (feature.imports or []);

  modulesForPlatform = fragments: platform:
    concatLists (
      map (fragment: let
        module = (fragment.modules or {}).${platform} or null;
      in
        if module == null
        then []
        else if builtins.isList module
        then module
        else [module])
      fragments
    );

  mergeFeatures = fragments: let
    merged = builtins.foldl' (acc: fragment: acc // builtins.removeAttrs fragment ["imports" "modules" "tests"]) {} fragments;
    platformNames = unique (concatLists (map (fragment: attrNames (fragment.modules or {})) fragments));
  in
    merged
    // {
      imports = concatLists (map featureImportEntries fragments);
      modules = listToAttrs (
        map (platform: {
          name = platform;
          value = modulesForPlatform fragments platform;
        })
        platformNames
      );
      tests = builtins.foldl' (acc: fragment: acc // (fragment.tests or {})) {} fragments;
    };

  loadFeaturePath = path: let
    feature = loadFeatureFile path;
    localFeatures = map loadFeaturePath (localImportEntries feature);
  in
    mergeFeatures (localFeatures ++ [feature]);

  loadFeature = name: loadFeaturePath (featureRoot + "/${name}");

  features = builtins.listToAttrs (
    map (name: {
      inherit name;
      value = loadFeature name;
    })
    featureNames
  );

  close = names: let
    go = seen: pending:
      if pending == []
      then seen
      else let
        name = builtins.head pending;
        rest = builtins.tail pending;
        feature =
          if hasAttr name features
          then features.${name}
          else throw "unknown feature '${name}'";
        next = feature.imports or [];
      in
        if builtins.elem name seen
        then go seen rest
        else go (seen ++ [name]) (rest ++ next);
  in
    go [] names;

  modulesFor = platform: names:
    concatLists (
      map (
        name:
          features.${name}.modules.${platform} or []
      )
      (filter (name: (features.${name}.modules.${platform} or []) != []) (close names))
    );

  missingFeatures = names: filter (name: !(hasAttr name features)) names;

  missingPlatformModules = platform: names:
    filter (
      name:
        hasAttr name features
        && (features.${name}.modules.${platform} or null) == null
    )
    names;

  serviceHosts = service:
    [service.primary] ++ (service.backups or []);

  serviceSecretRequirementsFor = services:
    concatLists (
      map (serviceName: let
        service = services.${serviceName};
        featureName = service.feature or serviceName;
        feature = features.${featureName} or {};
        mkRequirements = feature.serviceSecrets or (_: []);
      in
        mkRequirements {
          inherit service serviceName;
          hosts = serviceHosts service;
        })
      (attrNames services)
    );

  serviceFeaturePlatformModuleErrors = hosts: services:
    concatLists (
      map (serviceName: let
        service = services.${serviceName};
        featureName = service.feature or serviceName;
        feature = features.${featureName} or null;
        serviceHosts = [service.primary] ++ (service.backups or []);
      in
        if feature == null
        then []
        else
          concatLists (
            map (hostName: let
              host = hosts.${hostName} or null;
              platform = host.platform or fleetLib.platformForSystem host.system;
            in
              if host == null
              then []
              else if (feature.modules.${platform} or null) == null
              then ["service '${serviceName}' feature '${featureName}' has no ${platform} module for host '${hostName}'"]
              else [])
            serviceHosts
          ))
      (attrNames services)
    );

  tests = listToAttrs (
    concatLists (
      map (featureName:
        map (testName: {
          name = "${featureName}.${testName}";
          value = features.${featureName}.tests.${testName};
        })
        (attrNames (features.${featureName}.tests or {})))
      featureNames
    )
  );
in {
  inherit close featureNames features missingFeatures missingPlatformModules modulesFor serviceFeaturePlatformModuleErrors serviceSecretRequirementsFor tests;
}
