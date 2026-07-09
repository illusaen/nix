{
  config,
  inputs,
  lib,
  self,
  genValues,
  ...
}: let
  inherit (genValues) fleet;
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
        service = fleet.services.${name};
        mkEntry = role: host: {
          hostName = host.name;
          inherit name;
          service = service // {inherit role;};
        };
      in
        [(mkEntry "primary" service.host)]
        ++ map
        (mkEntry "backup")
        (builtins.filter (backup: backup.name != service.host.name) service.backups)
    )
    (builtins.attrNames fleet.services);

  serviceRoutesByHost =
    builtins.foldl' (
      routes: entry:
        routes
        // {
          ${entry.hostName} =
            (routes.${entry.hostName} or {})
            // {
              ${entry.name} = entry.service;
            };
        }
    ) {}
    serviceRouteEntries;

  routedServicesFor = host: serviceRoutesByHost.${host.name} or {};

  hostsByClass = class: lib.filterAttrs (_name: host: host.class == class) fleet.hosts;
  nixosHosts = hostsByClass "nixos";
  darwinHosts = hostsByClass "darwin";

  missingServiceModulesFor = class: routedServices:
    routedServices
    |> builtins.attrNames
    |> builtins.filter (name: classModuleNames class name == []);

  mkHostContext = {
    class,
    name,
    host,
    routedServices ? {},
    missingServiceModules ? [],
  }: let
    user = host.owner;
    resolvedHost =
      host
      // {
        services = routedServices;
      };
  in {
    specialArgs = {
      inherit fleet;
      host = resolvedHost;
      inherit self user;
    };

    module = {
      assertions = [
        {
          assertion = host.name == name;
          message = ''
            ${class} host ${name} injected host ${host.name},
            but expected fleet.hosts.${name}
          '';
        }
        {
          assertion = user.name == host.owner.name;
          message = ''
            ${class} host ${name} injected user ${user.name},
            but host ${host.name} has owner ${host.owner.name}
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
          inherit class name host routedServices missingServiceModules;
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

  config.flake = {
    inherit nixosConfigurations nixosIsoConfigurations darwinConfigurations;
  };

  config.perSystem = {system, ...}: let
    matchingNixosHostNames =
      nixosHosts
      |> lib.filterAttrs (_name: host: host.system == system)
      |> builtins.attrNames;

    systemPackages =
      matchingNixosHostNames
      |> map (name:
        lib.nameValuePair "system-${name}" nixosConfigurations.${name}.config.system.build.toplevel)
      |> builtins.listToAttrs;
    isoPackages =
      matchingNixosHostNames
      |> map (name:
        lib.nameValuePair "iso-${name}" nixosIsoConfigurations.${name}.config.system.build.isoImage)
      |> builtins.listToAttrs;
  in {
    legacyPackages = systemPackages // isoPackages;
  };
}
