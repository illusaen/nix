{
  config,
  inputs,
  lib,
  evalModulesModule,
  ...
}: let
  nixosCfg = config.nixos;
  darwinCfg = config.darwin;
  moduleClasses = ["generic" "nixos" "darwin"];

  mkDeferredModuleOption = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.deferredModule;
    default = {};
  };
  mkClassAttrsOption = type:
    lib.mkOption {
      type = lib.types.submodule {
        options = lib.genAttrs moduleClasses (_class:
          lib.mkOption {
            type = lib.types.lazyAttrsOf type;
            default = {};
          });
      };
      default = {};
    };

  classModuleNames = class: name:
    lib.optionals (config.flake.modules.generic ? ${name}) ["generic"]
    ++ lib.optionals (config.flake.modules.${class} ? ${name}) [class];

  moduleNameClosure = class: names: let
    go = seen: pending:
      if pending == []
      then seen
      else let
        name = builtins.head pending;
        rest = builtins.tail pending;
        children =
          (config.flake.moduleImports.generic.${name} or [])
          ++ (config.flake.moduleImports.${class}.${name} or []);
      in
        if lib.elem name seen
        then go seen rest
        else go (seen ++ [name]) (rest ++ children);
  in
    go [] names;

  modulesForNames = class: names:
    lib.concatMap (
      name:
        map (moduleClass: config.flake.modules.${moduleClass}.${name})
        (classModuleNames class name)
    )
    names;

  normalizeSettingsModule = raw:
    if raw ? imports || raw ? options || raw ? config
    then raw
    else {options = raw;};

  settingDeclarationModules = class: names:
    lib.concatMap (
      name: let
        classes = classModuleNames class name;
        declarations =
          classes
          |> builtins.filter (moduleClass: config.flake.moduleSettings.${moduleClass} ? ${name})
          |> map (moduleClass: normalizeSettingsModule config.flake.moduleSettings.${moduleClass}.${name});
      in
        lib.optional (declarations != []) {
          options.${name} = lib.mkOption {
            type = lib.types.submodule {imports = declarations;};
            default = {};
            description = "Settings for the ${name} module.";
          };
        }
    )
    names;

  resolveSettings = {
    class,
    activeNames,
    fleetSettings ? {},
    hostSettings ? {},
    userSettings ? {},
  }: let
    evaluated = lib.evalModules {
      modules =
        settingDeclarationModules class activeNames
        ++ [
          {config = lib.mkOverride 800 fleetSettings;}
          {config = lib.mkOverride 700 hostSettings;}
          {config = lib.mkOverride 600 userSettings;}
        ];
    };
  in
    evaluated.config;

  flattenSettings = prefix: value:
    if builtins.isAttrs value && !(value ? _type)
    then
      value
      |> lib.mapAttrsToList (name: flattenSettings (prefix ++ [name]))
      |> lib.concatLists
    else [prefix];

  hasPath = path: value:
    if path == []
    then true
    else if builtins.isAttrs value && builtins.hasAttr (builtins.head path) value
    then hasPath (builtins.tail path) value.${builtins.head path}
    else false;

  setPath = path: value:
    if path == []
    then value
    else {${builtins.head path} = setPath (builtins.tail path) value;};

  recursiveMerge = lib.foldl' lib.recursiveUpdate {};

  settingsProvenance = {
    resolved,
    fleetSettings ? {},
    hostSettings ? {},
    userSettings ? {},
  }: let
    paths = flattenSettings [] resolved;
    sourceFor = path:
      if hasPath path userSettings
      then "user"
      else if hasPath path hostSettings
      then "host"
      else if hasPath path fleetSettings
      then "fleet"
      else "default";
  in
    paths
    |> map (path: setPath path (sourceFor path))
    |> recursiveMerge;

  mkHostContext = {
    class,
    configurationName,
    hostName ? configurationName,
    activeNames ? [],
  }: let
    inherit (config) fleet;
    expectedHost =
      if lib.hasAttr hostName fleet.hosts
      then fleet.hosts.${hostName}
      else throw "${class}.configurations.${configurationName} has no matching fleet.hosts.${hostName}";

    host = expectedHost;
    user = host.owner;
    fleetSettings = resolveSettings {
      inherit class activeNames;
      fleetSettings = fleet.settings or {};
    };
    hostSettings = resolveSettings {
      inherit class activeNames;
      fleetSettings = fleet.settings or {};
      hostSettings = host.settings or {};
    };
    userSettings = resolveSettings {
      inherit class activeNames;
      fleetSettings = fleet.settings or {};
      hostSettings = host.settings or {};
      userSettings = user.settings or {};
    };
    resolvedFleet = fleet // {settings = fleetSettings;};
    resolvedHost = host // {settings = hostSettings;};
    resolvedUser = user // {settings = userSettings;};
    provenance = {
      fleet = settingsProvenance {
        resolved = fleetSettings;
        fleetSettings = fleet.settings or {};
      };
      host = settingsProvenance {
        resolved = hostSettings;
        fleetSettings = fleet.settings or {};
        hostSettings = host.settings or {};
      };
      user = settingsProvenance {
        resolved = userSettings;
        fleetSettings = fleet.settings or {};
        hostSettings = host.settings or {};
        userSettings = user.settings or {};
      };
    };
  in {
    specialArgs = {
      fleet = resolvedFleet;
      host = resolvedHost;
      user = resolvedUser;
      settings = hostSettings;
      settingsProvenance = provenance;
    };

    module = {
      assertions = [
        {
          assertion = host.id_hash == expectedHost.id_hash;
          message = ''
            ${class}.configurations.${configurationName} injected host ${host.name},
            but expected fleet.hosts.${expectedHost.name}
            (id_hash ${host.id_hash} vs ${expectedHost.id_hash}).
          '';
        }
        {
          assertion = host.owner != null;
          message = "fleet.hosts.${hostName}.owner must be set";
        }
        {
          assertion = user.id_hash == host.owner.id_hash;
          message = ''
            ${class}.configurations.${configurationName} injected user ${user.name},
            but host ${host.name} has owner ${host.owner.name}
            (id_hash ${user.id_hash} vs ${host.owner.id_hash}).
          '';
        }
      ];
    };
  };

  mkConfigurationsOption = {
    class,
    fn,
  }:
    lib.mkOption {
      type = lib.types.lazyAttrsOf (
        lib.types.submodule (
          args @ {name, ...}: let
            configuration = args.config;
            activeNames = moduleNameClosure class configuration.moduleNames;
            ctx = mkHostContext {
              inherit class;
              configurationName = name;
              hostName = configuration.host;
              inherit activeNames;
            };
          in {
            options.host = lib.mkOption {
              type = lib.types.str;
              default = name;
              description = "Fleet host to use for this ${class} configuration.";
            };
            options.moduleNames = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [];
              apply = lib.unique;
              description = "Named flake modules to import for this ${class} configuration.";
            };
            options.extraModule = lib.mkOption {
              type = lib.types.deferredModule;
              default = {};
              description = "Ad-hoc ${class} module imported after named modules.";
            };

            imports = [
              evalModulesModule
              {
                inherit fn;
                args.specialArgs = ctx.specialArgs;
                module = {
                  imports = [ctx.module] ++ modulesForNames class activeNames ++ [configuration.extraModule];
                  networking.hostName = lib.mkDefault ctx.specialArgs.host.name;
                  nixpkgs.hostPlatform = lib.mkDefault ctx.specialArgs.host.system;
                };
              }
            ];
          }
        )
      );
      default = {};
    };

  mkChecks = class: configurations:
    configurations
    |> lib.mapAttrsToList (
      name: {evaluation, ...}: {
        ${evaluation.config.nixpkgs.hostPlatform.system} = {
          "configurations:${class}:${name}" = evaluation.config.system.build.toplevel;
        };
      }
    );

  processConfigurations = configurations: configurations |> lib.mapAttrs (_name: {evaluation, ...}: evaluation);
in {
  options.flake.moduleImports = mkClassAttrsOption (lib.types.listOf lib.types.str);
  options.flake.moduleSettings = mkClassAttrsOption lib.types.raw;

  options.nixos = {
    modules = mkDeferredModuleOption;
    configurations = mkConfigurationsOption {
      class = "nixos";
      fn = lib.nixosSystem;
    };
  };

  options.darwin = {
    modules = mkDeferredModuleOption;
    configurations = mkConfigurationsOption {
      class = "darwin";
      fn = inputs.darwin.lib.darwinSystem;
    };
  };

  config.flake = {
    nixosConfigurations = processConfigurations nixosCfg.configurations;
    darwinConfigurations = processConfigurations darwinCfg.configurations;

    checks =
      (mkChecks "nixos" nixosCfg.configurations)
      ++ (mkChecks "darwin" darwinCfg.configurations)
      |> lib.mkMerge;
  };
}
