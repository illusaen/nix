{
  config,
  inputs,
  lib,
  evalModulesModule,
  ...
}: let
  nixosCfg = config.nixos;
  darwinCfg = config.darwin;

  mkDeferredModuleOption = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.deferredModule;
    default = {};
  };

  mkHostContext = {
    class,
    configurationName,
    hostName ? configurationName,
  }: let
    inherit (config) fleet;
    expectedHost =
      if lib.hasAttr hostName fleet.hosts
      then fleet.hosts.${hostName}
      else throw "${class}.configurations.${configurationName} has no matching fleet.hosts.${hostName}";

    host = expectedHost;
    user = host.owner;
  in {
    specialArgs = {
      inherit fleet host user;
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
            ctx = mkHostContext {
              inherit class;
              configurationName = name;
              hostName = configuration.host;
            };
          in {
            options.host = lib.mkOption {
              type = lib.types.str;
              default = name;
              description = "Fleet host to use for this ${class} configuration.";
            };

            imports = [
              evalModulesModule
              {
                inherit fn;
                args.specialArgs = ctx.specialArgs;
                module = {
                  imports = [ctx.module];
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
