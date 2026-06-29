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
    name,
    host,
    activeNames ? [],
  }: let
    inherit (config) fleet;
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
          assertion = host.id_hash == fleet.hosts.${name}.id_hash;
          message = ''
            ${class} host ${name} injected host ${host.name},
            but expected fleet.hosts.${name}
            (id_hash ${host.id_hash} vs ${fleet.hosts.${name}.id_hash}).
          '';
        }
        {
          assertion = host.owner != null;
          message = "fleet.hosts.${name}.owner must be set";
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
          networking.hostName = lib.mkDefault ctx.specialArgs.host.name;
          nixpkgs.hostPlatform = lib.mkDefault ctx.specialArgs.host.system;
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
  options.flake.moduleSettings = mkClassAttrsOption lib.types.raw;

  config.flake = {
    inherit nixosConfigurations darwinConfigurations;

    checks =
      (mkChecks "nixos" nixosConfigurations)
      ++ (mkChecks "darwin" darwinConfigurations)
      |> lib.mkMerge;
  };
}
