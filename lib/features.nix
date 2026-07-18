{
  lib,
  sources,
}: let
  inherit (builtins) attrNames concatLists concatMap filter hasAttr listToAttrs readDir;
  inherit (lib) concatMapAttrs mapAttrs' mapAttrsToList nameValuePair optionals pipe unique filterAttrs;

  concatMapAttrsToList = f: attrs:
    pipe attrs [
      (mapAttrsToList f)
      concatLists
    ];

  featureRoot = ../features;

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

  assertSupported = {
    path,
    feature,
    message,
    unsupported,
    supported,
  }:
    if unsupported == []
    then feature
    else
      throw ''
        feature file '${toString path}' declares unsupported ${message}: ${builtins.concatStringsSep ", " unsupported}
        supported ${message}: ${builtins.concatStringsSep ", " supported}
      '';

  assertSupportedFeatureAttrs = path: feature: let
    supported = ["imports" "modules" "tests" "serviceSecrets"];
  in
    assertSupported {
      inherit path feature supported;
      unsupported = filter (name: !(builtins.elem name supported)) (attrNames feature);
      message = "attributes";
    };

  assertSupportedModulePlatforms = path: feature: let
    supported = ["generic" "nixos" "darwin"];
  in
    assertSupported {
      inherit path feature supported;
      unsupported = filter (platform: !(builtins.elem platform supported)) (attrNames (feature.modules or {}));
      message = "module platforms";
    };

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
  in {
    imports = concatMap featureImportEntries fragments;
    modules = listToAttrs (
      map (platform: {
        name = platform;
        value = modulesForPlatform fragments platform;
      })
      platformNames
    );
    tests = builtins.foldl' (acc: fragment: acc // (fragment.tests or {})) {} fragments;
    serviceSecrets = args:
      concatMap (fragment: (fragment.serviceSecrets or (_: [])) args) fragments;
  };

  loadFeaturePath = path: let
    feature = assertSupportedModulePlatforms path (assertSupportedFeatureAttrs path (callFeature (import path)));
    localFeatures = map loadFeaturePath (localImportEntries feature);
  in
    mergeFeatures (localFeatures ++ [feature]);

  serviceHosts = service:
    [service.primary] ++ (service.backups or []);

  features = pipe featureRoot [
    readDir
    (filterAttrs (_name: value: value == "directory"))
    (builtins.mapAttrs (name: _value: (loadFeaturePath (featureRoot + "/${name}"))))
  ];
in rec {
  tests =
    (concatMapAttrs (
        featureName: feature:
          mapAttrs' (testName: test: nameValuePair "${featureName}.${testName}" test) (feature.tests or {})
      )
      features)
    // {
      unsupportedModulePlatformsRejected =
        !(builtins.tryEval (assertSupportedModulePlatforms "test-feature" {
          modules.linux = {};
        })).success;
      unsupportedFeatureAttrsRejected =
        !(builtins.tryEval (assertSupportedFeatureAttrs "test-feature" {
          module.nixos = {};
        })).success;
      serviceSecretsMerged =
        (mergeFeatures [
          {serviceSecrets = _: ["first"];}
          {serviceSecrets = _: ["second"];}
        ]).serviceSecrets {}
        == ["first" "second"];
    };

  missingFeatures = names: filter (name: !(hasAttr name features)) names;

  missingPlatformModules = platform: names:
    filter (
      name:
        hasAttr name features
        && (features.${name}.modules.${platform} or null) == null
    )
    names;

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

  featuresForHost = {
    host,
    services ? [],
  }: let
    tags = host.tags or [];
    isLinux = host.platform == "nixos";
    isDesktop = builtins.elem "desktop" tags;
  in
    pipe [
      ["base"]
      (optionals isLinux ["boot"])
      (optionals isDesktop ["programs-core" "theming"])
      (optionals (isLinux && isDesktop) ["desktop-shell"])
      (optionals (builtins.elem "gpu:nvidia" tags) ["nvidia"])
      (concatMap (
          tag: let
            match = builtins.match "feature:(.+)" tag;
          in
            if match == null
            then []
            else ["programs-${builtins.head match}"]
        )
        tags)
      (optionals (host.preservation.enable or false) ["preservation"])
      host.features
      (builtins.catAttrs "feature" services)
    ] [
      concatLists
      unique
    ];

  modulesForHost = host:
    pipe {
      inherit host;
      services = host.services or [];
    } [
      featuresForHost
      close
      (concatMap (
        name:
          features.${name}.modules.${host.platform} or []
      ))
    ];

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
              if (feature.modules.${platform} or null) == null
              then ["service '${serviceName}' feature '${featureName}' has no ${platform} module for host '${hostName}'"]
              else []
          )
          (serviceHosts service)
    )
    services;
}
