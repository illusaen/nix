{
  lib ? import ((import ../npins).nixpkgs.outPath + "/lib"),
  sources ? import ../npins,
}: let
  inherit (builtins) attrNames concatLists filter hasAttr listToAttrs readDir;
  inherit (lib) pipe unique;

  featureRoot = ../features;
  featureEntries = readDir featureRoot;

  featureNamesFrom = entries:
    pipe entries [
      attrNames
      (filter (name: entries.${name} == "directory"))
    ];

  callFeature = feature:
    if builtins.isFunction feature
    then
      feature {
        inherit sources;
      }
    else feature;

  loadFeatureFile = path: callFeature (import path);

  featureImportEntries = feature:
    filter builtins.isString (feature.imports or []);

  localImportEntries = feature:
    filter (entry: !builtins.isString entry) (feature.imports or []);

  moduleList = modules: platform: let
    module = modules.${platform} or null;
  in
    if module == null
    then []
    else if builtins.isList module
    then module
    else [module];

  modulesForPlatform = fragments: platform:
    pipe fragments [
      (map (fragment: let
        modules = fragment.modules or {};
      in
        moduleList modules "generic" ++ moduleList modules platform))
      concatLists
    ];

  mergeFeatures = fragments: let
    merged = builtins.foldl' (acc: fragment: acc // removeAttrs fragment ["imports" "modules" "tests"]) {} fragments;
    modulePlatformNames = pipe fragments [
      (map (fragment: attrNames (fragment.modules or {})))
      concatLists
    ];
    platformNames =
      if builtins.elem "generic" modulePlatformNames
      then
        pipe modulePlatformNames [
          (filter (platform: platform != "generic"))
          (platforms: ["nixos" "darwin"] ++ platforms)
          unique
        ]
      else unique modulePlatformNames;
  in
    merged
    // {
      imports = pipe fragments [
        (map featureImportEntries)
        concatLists
      ];
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

  serviceHosts = service:
    [service.primary] ++ (service.backups or []);
in rec {
  tests = pipe featureEntries [
    featureNamesFrom
    (map (featureName:
      map (testName: lib.nameValuePair "${featureName}.${testName}" features.${featureName}.tests.${testName})
      (attrNames (features.${featureName}.tests or {}))))
    concatLists
    listToAttrs
  ];

  missingFeatures = names: filter (name: !(hasAttr name features)) names;

  missingPlatformModules = platform: names:
    filter (
      name:
        hasAttr name features
        && (features.${name}.modules.${platform} or null) == null
    )
    names;

  features = pipe featureEntries [
    featureNamesFrom
    (map (name: lib.nameValuePair name (loadFeature name)))
    listToAttrs
  ];

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
    pipe (close names) [
      (filter (name: (features.${name}.modules.${platform} or []) != []))
      (map (
        name:
          features.${name}.modules.${platform} or []
      ))
      concatLists
    ];

  serviceSecretRequirementsFor = services:
    pipe services [
      attrNames
      (map (serviceName: let
        service = services.${serviceName};
        featureName = service.feature or serviceName;
        feature = features.${featureName} or {};
        mkRequirements = feature.serviceSecrets or (_: []);
      in
        mkRequirements {
          inherit service serviceName;
          hosts = serviceHosts service;
        }))
      concatLists
    ];

  serviceFeaturePlatformModuleErrors = hosts: services:
    pipe services [
      attrNames
      (map (serviceName: let
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
              inherit (host) platform;
            in
              if host == null
              then []
              else if (feature.modules.${platform} or null) == null
              then ["service '${serviceName}' feature '${featureName}' has no ${platform} module for host '${hostName}'"]
              else [])
            serviceHosts
          )))
      concatLists
    ];
}
