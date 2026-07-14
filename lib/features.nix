{fleetLib ? import ./fleet.nix {}}: let
  inherit (builtins) attrNames concatLists filter hasAttr listToAttrs map readDir;

  featureRoot = ../features;

  featureNames =
    filter (name: (readDir featureRoot).${name} == "directory")
    (attrNames (readDir featureRoot));

  loadFeature = name: let
    feature = import (featureRoot + "/${name}");
  in
    if builtins.isFunction feature
    then feature {}
    else feature;

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
    map (name: features.${name}.modules.${platform})
    (filter (name: (features.${name}.modules.${platform} or null) != null) (close names));

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
