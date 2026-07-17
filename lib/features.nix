{
  lib,
  sources,
}: let
  inherit (builtins) attrNames concatLists concatMap filter hasAttr listToAttrs readDir;
  inherit (lib) concatMapAttrs mapAttrs' mapAttrsToList nameValuePair optionals pipe unique;

  concatMapAttrsToList = f: attrs:
    pipe attrs [
      (mapAttrsToList f)
      concatLists
    ];

  featureRoot = ../features;
  featureEntries = readDir featureRoot;
  featureNames = filter (name: featureEntries.${name} == "directory") (attrNames featureEntries);

  callFeature = feature:
    if builtins.isFunction feature
    then
      feature {
        inherit sources;
      }
    else feature;

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
    concatMap (
      fragment: let
        modules = fragment.modules or {};
      in
        moduleList modules "generic" ++ moduleList modules platform
    )
    fragments;

  mergeFeatures = fragments: let
    merged = builtins.foldl' (acc: fragment: acc // removeAttrs fragment ["imports" "modules" "tests"]) {} fragments;
    modulePlatformNames = concatMap (fragment: attrNames (fragment.modules or {})) fragments;
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
      imports = concatMap featureImportEntries fragments;
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
    feature = callFeature (import path);
    localFeatures = map loadFeaturePath (localImportEntries feature);
  in
    mergeFeatures (localFeatures ++ [feature]);

  loadFeature = name: loadFeaturePath (featureRoot + "/${name}");

  serviceHosts = service:
    [service.primary] ++ (service.backups or []);

  tagFeatureNames = tags:
    concatMap (
      tag: let
        match = builtins.match "feature:(.+)" tag;
      in
        if match == null
        then []
        else ["programs-${builtins.head match}"]
    )
    tags;

  derivedHostFeatures = host: let
    tags = host.tags or [];
    isLinux = host.platform == "nixos";
    isDesktop = builtins.elem "desktop" tags;
  in
    unique (
      ["base"]
      ++ optionals isLinux ["boot"]
      ++ optionals isDesktop ["programs-core" "theming"]
      ++ optionals (isLinux && isDesktop) ["desktop-shell"]
      ++ optionals (builtins.elem "gpu:nvidia" tags) ["nvidia"]
      ++ tagFeatureNames tags
      ++ optionals (host.preservation.enable or false) ["preservation"]
    );
in rec {
  tests =
    concatMapAttrs (
      featureName: feature:
        mapAttrs' (testName: test: nameValuePair "${featureName}.${testName}" test) (feature.tests or {})
    )
    features;

  missingFeatures = names: filter (name: !(hasAttr name features)) names;

  missingPlatformModules = platform: names:
    filter (
      name:
        hasAttr name features
        && (features.${name}.modules.${platform} or null) == null
    )
    names;

  features = pipe featureNames [
    (map (name: nameValuePair name (loadFeature name)))
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
    concatMap (
      name:
        features.${name}.modules.${platform} or []
    )
    (close names);

  featuresForHost = {
    host,
    services ? [],
  }:
    unique (derivedHostFeatures host ++ host.features ++ builtins.catAttrs "feature" services);

  serviceSecretRequirementsFor = services:
    concatMapAttrsToList (
      serviceName: service: let
        featureName = service.feature or serviceName;
        feature = features.${featureName} or {};
        mkRequirements = feature.serviceSecrets or (_: []);
      in
        mkRequirements {
          inherit service serviceName;
          hosts = serviceHosts service;
        }
    )
    services;

  serviceFeaturePlatformModuleErrors = hosts: services:
    concatMapAttrsToList (
      serviceName: service: let
        featureName = service.feature or serviceName;
        feature = features.${featureName} or null;
      in
        if feature == null
        then []
        else
          concatMap (
            hostName: let
              host = hosts.${hostName} or null;
              inherit (host) platform;
            in
              if host == null
              then []
              else if (feature.modules.${platform} or null) == null
              then ["service '${serviceName}' feature '${featureName}' has no ${platform} module for host '${hostName}'"]
              else []
          )
          (serviceHosts service)
    )
    services;
}
