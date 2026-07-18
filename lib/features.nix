{
  lib,
  sources,
}: let
  inherit (builtins) attrNames concatLists concatMap filter hasAttr listToAttrs readDir concatStringsSep elem;
  inherit (lib) concatMapAttrs mapAttrs' mapAttrsToList nameValuePair optionals pipe unique filterAttrs;

  concatMapAttrsToList = f: attrs:
    concatLists (mapAttrsToList f attrs);

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
        feature file '${toString path}' declares unsupported ${message}: ${concatStringsSep ", " unsupported}
        supported ${message}: ${concatStringsSep ", " supported}
      '';

  assertSupportedFeatureAttrs = path: feature: let
    supported = ["imports" "modules" "tests" "serviceSecrets"];
  in
    assertSupported {
      inherit path feature supported;
      unsupported = filter (name: !(elem name supported)) (attrNames feature);
      message = "attributes";
    };

  assertSupportedModulePlatforms = path: feature: let
    supported = ["generic" "nixos" "darwin"];
  in
    assertSupported {
      inherit path feature supported;
      unsupported = filter (platform: !(elem platform supported)) (attrNames (feature.modules or {}));
      message = "module platforms";
    };

  assertFeatureTypes = path: feature: let
    imports = feature.imports or [];
    errors =
      optionals (!builtins.isList imports) ["imports must be a list"]
      ++ optionals (builtins.isList imports && !builtins.all builtins.isPath imports) ["imports must contain only paths"]
      ++ optionals (feature ? modules && !builtins.isAttrs feature.modules) ["modules must be an attribute set"]
      ++ optionals (feature ? tests && !builtins.isAttrs feature.tests) ["tests must be an attribute set"]
      ++ optionals (feature ? serviceSecrets && !builtins.isFunction feature.serviceSecrets) ["serviceSecrets must be a function"];
  in
    if errors == []
    then feature
    else throw "feature file '${toString path}' has invalid fields: ${concatStringsSep "; " errors}";

  mergeFeatures = fragments: let
    declaredModulePlatforms = concatMap (fragment: attrNames (fragment.modules or {})) fragments;
    platformNames =
      filter
      (platform: elem "generic" declaredModulePlatforms || elem platform declaredModulePlatforms)
      ["nixos" "darwin"];
  in {
    modules = listToAttrs (
      map (platform: {
        name = platform;
        value =
          concatMap (
            fragment: let
              modules = fragment.modules or {};
              moduleList = platform: lib.optionals ((modules.${platform} or null) != null) (lib.toList modules.${platform});
            in
              moduleList "generic" ++ moduleList platform
          )
          fragments;
      })
      platformNames
    );
    tests = builtins.foldl' (acc: fragment: acc // (fragment.tests or {})) {} fragments;
    serviceSecrets = args:
      concatMap (fragment: (fragment.serviceSecrets or (_: [])) args) fragments;
  };

  loadFeaturePath = path: let
    callFeature = feature:
      if builtins.isFunction feature
      then
        feature {
          inherit sources;
        }
      else feature;
    feature = pipe (callFeature (import path)) [
      (assertSupportedFeatureAttrs path)
      (assertFeatureTypes path)
      (assertSupportedModulePlatforms path)
    ];
    localFeatures = map loadFeaturePath (feature.imports or []);
  in
    mergeFeatures (localFeatures ++ [feature]);

  serviceHosts = service:
    [service.primary] ++ (service.backups or []);

  features = let
    featureRoot = ../features;
  in
    pipe featureRoot [
      readDir
      (filterAttrs (_name: value: value == "directory"))
      (builtins.mapAttrs (name: _value: (loadFeaturePath (featureRoot + "/${name}"))))
    ];
in rec {
  tests =
    (concatMapAttrs (
        featureName: feature:
          mapAttrs' (testName: test: nameValuePair "${featureName}.${testName}" test) feature.tests
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
      invalidFeatureImportsRejected =
        !(builtins.tryEval (assertFeatureTypes "test-feature" {
          imports = ["base"];
        })).success;
      invalidFeatureModulesRejected =
        !(builtins.tryEval (assertFeatureTypes "test-feature" {
          modules = [];
        })).success;
      invalidFeatureTestsRejected =
        !(builtins.tryEval (assertFeatureTypes "test-feature" {
          tests = [];
        })).success;
      invalidFeatureServiceSecretsRejected =
        !(builtins.tryEval (assertFeatureTypes "test-feature" {
          serviceSecrets = [];
        })).success;
      serviceSecretsMerged =
        (mergeFeatures [
          {serviceSecrets = _: ["first"];}
          {serviceSecrets = _: ["second"];}
        ]).serviceSecrets {}
        == ["first" "second"];
      unknownHostFeatureRejected =
        !(builtins.tryEval (modulesForHost {
          name = "test-host";
          platform = "nixos";
          tags = [];
          features = ["missing"];
          preservation.enable = false;
        })).success;
      unsupportedHostFeaturePlatformRejected =
        !(builtins.tryEval (
          modulesForHost {
            name = "test-host";
            platform = "darwin";
            tags = [];
            features = ["nvidia"];
            preservation.enable = false;
          }
        )).success;
    };

  missingFeatures = names: filter (name: !(hasAttr name features)) names;

  missingPlatformModules = platform: names:
    filter (
      name:
        hasAttr name features
        && !hasAttr platform features.${name}.modules
    )
    names;

  featuresForHost = {
    host,
    services ? [],
  }: let
    tags = host.tags or [];
    isLinux = host.platform == "nixos";
    isDesktop = builtins.elem "desktop" tags;
    featureGroups = [
      ["base"]
      (optionals isLinux ["boot"])
      (optionals isDesktop ["programs-core" "theming"])
      (optionals (isLinux && isDesktop) ["desktop-shell"])
      (optionals (builtins.elem "gpu:nvidia" tags) ["nvidia"])
      (concatMap (
          tag: let
            match = builtins.match "feature:(.+)" tag;
          in
            optionals (match != null) ["programs-${builtins.head match}"]
        )
        tags)
      (optionals (host.preservation.enable or false) ["preservation"])
      host.features
      (builtins.catAttrs "feature" services)
    ];
  in
    unique (concatLists featureGroups);

  modulesForHost = host: let
    names = featuresForHost {
      inherit host;
      services = host.services or [];
    };
    missing = missingFeatures names;
    unsupported = missingPlatformModules host.platform names;
  in
    if missing != []
    then throw "host '${host.name}' references unknown features: ${concatStringsSep ", " missing}"
    else if unsupported != []
    then throw "host '${host.name}' references features without ${host.platform} modules: ${concatStringsSep ", " unsupported}"
    else concatMap (name: features.${name}.modules.${host.platform}) names;

  serviceSecretRequirementsFor = services:
    concatMapAttrsToList (
      serviceName: service: let
        featureName = service.feature or serviceName;
        feature = features.${featureName} or {};
        mkRequirements = feature.serviceSecrets or (_: []);
      in
        mkRequirements {
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
              if !hasAttr platform feature.modules
              then ["service '${serviceName}' feature '${featureName}' has no ${platform} module for host '${hostName}'"]
              else []
          )
          (serviceHosts service)
    )
    services;
}
