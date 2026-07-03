{
  config,
  inputs,
  lib,
  self,
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

  moduleNameClosure = names: let
    go = seen: pending:
      if pending == []
      then seen
      else let
        name = builtins.head pending;
        rest = builtins.tail pending;
        children = config.flake.moduleImports.${name} or [];
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

  serviceRouteEntries =
    lib.concatMap (
      name: let
        service = config.fleet.services.${name};
        mkEntry = role: host: {
          hostHash = host.id_hash;
          inherit name;
          service = service // {inherit role;};
        };
      in
        [(mkEntry "primary" service.host)]
        ++ map
        (mkEntry "backup")
        (builtins.filter (backup: backup.id_hash != service.host.id_hash) service.backups)
    )
    (builtins.attrNames config.fleet.services);

  serviceRoutesByHost =
    builtins.foldl' (
      routes: entry:
        routes
        // {
          ${entry.hostHash} =
            (routes.${entry.hostHash} or {})
            // {
              ${entry.name} = entry.service;
            };
        }
    ) {}
    serviceRouteEntries;

  routedServicesFor = host: serviceRoutesByHost.${host.id_hash} or {};

  hostsByClass = class: lib.filterAttrs (_name: host: host.class == class) config.fleet.hosts;
  nixosHosts = hostsByClass "nixos";
  darwinHosts = hostsByClass "darwin";

  missingServiceModulesFor = class: routedServices:
    routedServices
    |> builtins.attrNames
    |> builtins.filter (name: classModuleNames class name == []);

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

  mkHostContext = {
    class,
    name,
    host,
    routedServices ? {},
    missingServiceModules ? [],
    activeNames ? [],
  }: let
    inherit (config) fleet;
    user = host.owner;
    hostModuleSettings = resolveModuleSettings {
      inherit class activeNames;
      fleetModuleSettings = fleet.moduleSettings or {};
      hostModuleSettings = host.moduleSettings or {};
      userModuleSettings = user.moduleSettings or {};
    };
    resolvedHost =
      host
      // {
        moduleSettings = hostModuleSettings;
        services = routedServices;
      };
  in {
    specialArgs = {
      fleet = fleet // {moduleSettings = hostModuleSettings;};
      host = resolvedHost;
      user = user // {moduleSettings = hostModuleSettings;};
      inherit self;
      moduleSettings = hostModuleSettings;
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
        {
          assertion = missingServiceModules == [];
          message = ''
            ${class} host ${name} has routed services without matching flake modules:
            ${lib.concatStringsSep ", " missingServiceModules}
          '';
        }
      ];
    };
  };

  mkConfigurationsOption = {
    class,
    fn,
    hosts,
    extraModuleNames ? [],
  }:
    hosts
    |> lib.mapAttrs (
      name: host: let
        routedServices = routedServicesFor host;
        routedServiceNames = builtins.attrNames routedServices;
        missingServiceModules = missingServiceModulesFor class routedServices;
        activeNames = moduleNameClosure (host.moduleNames ++ routedServiceNames ++ extraModuleNames);
        ctx = mkHostContext {
          inherit class name host routedServices missingServiceModules activeNames;
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

  nixosConfigurations = mkConfigurationsOption {
    class = "nixos";
    fn = lib.nixosSystem;
    hosts = nixosHosts;
  };
  nixosIsoConfigurations = mkConfigurationsOption {
    class = "nixos";
    fn = lib.nixosSystem;
    hosts = nixosHosts;
    extraModuleNames = ["iso"];
  };
  darwinConfigurations =
    if darwinHosts == {}
    then {}
    else
      mkConfigurationsOption {
        class = "darwin";
        fn = inputs.darwin.lib.darwinSystem;
        hosts = darwinHosts;
      };
in {
  options.flake.moduleImports = lib.mkOption {
    type = lib.types.lazyAttrsOf (lib.types.listOf lib.types.str);
    default = {};
  };
  options.flake.moduleOptions = mkClassAttrsOption lib.types.raw;

  config.flake = {
    inherit nixosConfigurations nixosIsoConfigurations darwinConfigurations;
  };

  config.perSystem = {system, ...}: let
    matchingNixosConfigurations = lib.filterAttrs (_name: host: host.config.nixpkgs.hostPlatform.system == system) nixosConfigurations;
    matchingIsoConfigurations = lib.filterAttrs (_name: host: host.config.nixpkgs.hostPlatform.system == system) nixosIsoConfigurations;

    systemPackages =
      matchingNixosConfigurations
      |> lib.mapAttrs' (name: host:
        lib.nameValuePair "system-${name}" host.config.system.build.toplevel);
    isoPackages =
      matchingIsoConfigurations
      |> lib.mapAttrs' (name: host:
        lib.nameValuePair "iso-${name}" host.config.system.build.isoImage);
  in {
    packages = systemPackages // isoPackages;
  };
}
