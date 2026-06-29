{
  config,
  inputs,
  lib,
  ...
}: let
  moduleClasses = ["generic" "nixos" "darwin"];
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
          |> builtins.filter (moduleClass: config.flake.moduleOptions.${moduleClass} ? ${name})
          |> map (moduleClass: normalizeSettingsModule config.flake.moduleOptions.${moduleClass}.${name});
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

  resolveModuleSettings = {
    class,
    activeNames,
    fleetModuleSettings ? {},
    hostModuleSettings ? {},
    userModuleSettings ? {},
  }: let
    evaluated = lib.evalModules {
      modules =
        settingDeclarationModules class activeNames
        ++ [
          {config = lib.mkOverride 800 fleetModuleSettings;}
          {config = lib.mkOverride 700 hostModuleSettings;}
          {config = lib.mkOverride 600 userModuleSettings;}
        ];
    };
  in
    evaluated.config;

  flattenModuleSettings = prefix: value:
    if builtins.isAttrs value && !(value ? _type)
    then
      value
      |> lib.mapAttrsToList (name: flattenModuleSettings (prefix ++ [name]))
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

  moduleSettingsProvenance = {
    resolved,
    fleetModuleSettings ? {},
    hostModuleSettings ? {},
    userModuleSettings ? {},
  }: let
    paths = flattenModuleSettings [] resolved;
    sourceFor = path:
      if hasPath path userModuleSettings
      then "user"
      else if hasPath path hostModuleSettings
      then "host"
      else if hasPath path fleetModuleSettings
      then "fleet"
      else "default";
  in
    paths
    |> map (path: setPath path (sourceFor path))
    |> recursiveMerge;

  mkHostContext = {
    class,
    name,
    host,
    activeNames ? [],
  }: let
    inherit (config) fleet;
    user = host.owner;
    fleetModuleSettings = resolveModuleSettings {
      inherit class activeNames;
      fleetModuleSettings = fleet.moduleSettings or {};
    };
    hostModuleSettings = resolveModuleSettings {
      inherit class activeNames;
      fleetModuleSettings = fleet.moduleSettings or {};
      hostModuleSettings = host.moduleSettings or {};
    };
    userModuleSettings = resolveModuleSettings {
      inherit class activeNames;
      fleetModuleSettings = fleet.moduleSettings or {};
      hostModuleSettings = host.moduleSettings or {};
      userModuleSettings = user.moduleSettings or {};
    };
    resolvedFleet = fleet // {moduleSettings = fleetModuleSettings;};
    resolvedHost = host // {moduleSettings = hostModuleSettings;};
    resolvedUser = user // {moduleSettings = userModuleSettings;};
    provenance = {
      fleet = moduleSettingsProvenance {
        resolved = fleetModuleSettings;
        fleetModuleSettings = fleet.moduleSettings or {};
      };
      host = moduleSettingsProvenance {
        resolved = hostModuleSettings;
        fleetModuleSettings = fleet.moduleSettings or {};
        hostModuleSettings = host.moduleSettings or {};
      };
      user = moduleSettingsProvenance {
        resolved = userModuleSettings;
        fleetModuleSettings = fleet.moduleSettings or {};
        hostModuleSettings = host.moduleSettings or {};
        userModuleSettings = user.moduleSettings or {};
      };
    };
  in {
    specialArgs = {
      fleet = resolvedFleet;
      host = resolvedHost;
      user = resolvedUser;
      moduleSettings = hostModuleSettings;
      moduleSettingsProvenance = provenance;
    };

    module = {
      assertions = [
        {
          assertion = host.id_hash == fleet.hosts.${name}.id_hash;
          message = ''
            ${class} host ${name} injected host ${host.name},
            but expected fleet.hosts.${name}
            (id_hash ${host.id_hash} vs ${fleet.hosts.${name}.id_hash}).
          '';
        }
        {
          assertion = user.id_hash == host.owner.id_hash;
          message = ''
            ${class} host ${name} injected user ${user.name},
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
    hosts,
  }:
    hosts
    |> lib.filterAttrs (_name: host: host.class == class)
    |> lib.mapAttrs (
      name: host: let
        activeNames = moduleNameClosure class host.moduleNames;
        ctx = mkHostContext {
          inherit class name host activeNames;
        };
        evaluationModule = {
          imports = [ctx.module] ++ modulesForNames class activeNames ++ [host.extraModule];
        };
      in
        fn {
          inherit (ctx) specialArgs;
          modules = [evaluationModule];
        }
    );

  mkChecks = class: configurations:
    configurations
    |> lib.mapAttrsToList (
      name: evaluation: {
        ${evaluation.config.nixpkgs.hostPlatform.system} = {
          "configurations:${class}:${name}" = evaluation.config.system.build.toplevel;
        };
      }
    );

  nixosConfigurations = mkConfigurationsOption {
    class = "nixos";
    fn = lib.nixosSystem;
    hosts = config.fleet.hosts;
  };
  darwinConfigurations = mkConfigurationsOption {
    class = "darwin";
    fn = inputs.darwin.lib.darwinSystem;
    hosts = config.fleet.hosts;
  };
in {
  options.flake.moduleImports = mkClassAttrsOption (lib.types.listOf lib.types.str);
  options.flake.moduleOptions = mkClassAttrsOption lib.types.raw;

  config.flake = {
    inherit nixosConfigurations darwinConfigurations;

    checks =
      (mkChecks "nixos" nixosConfigurations)
      ++ (mkChecks "darwin" darwinConfigurations)
      |> lib.mkMerge;
  };
}
