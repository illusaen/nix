{
  config,
  inputs,
  lib,
  self,
  ...
}: {
  imports = [inputs.wrappers.flakeModules.wrappers];

  options.flake = lib.mkOption {
    type = lib.types.submoduleWith {
      modules = [
        ({options, ...}: {
          options.fleetWrappers = lib.mkOption {
            type = lib.types.lazyAttrsOf (inputs.wrappers.lib.types.subWrapperModuleWith {
              specialArgs = {
                inherit (config) fleet;
              };
            });
            default = {};
            description = ''
              Fleet-aware wrapper modules.

              Use flake.wrappers for the original wrapper shape when fleet
              context is not needed. Use flake.fleetWrappers when a wrapper
              needs fleet-level schema data during wrapper evaluation.
            '';
          };
          options.fleetWrapperModules = lib.mkOption {
            type = lib.types.lazyAttrsOf lib.types.deferredModule;
            readOnly = true;
            description = ''
              Importable module declarations generated from flake.fleetWrappers.
            '';
          };
          config.fleetWrapperModules =
            (lib.types.lazyAttrsOf lib.types.deferredModule).merge
            options.fleetWrappers.loc
            options.fleetWrappers.definitionsWithLocations;
        })
      ];
    };
  };

  config = {
    flake-file.inputs.wrappers = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    flake.wrappers =
      builtins.mapAttrs (_: module: {
        imports = lib.toList module;
        _module.args.fleet = config.fleet;
      })
      config.flake.fleetWrapperModules;
    flake.nixosModules = builtins.mapAttrs (_: v: v.install) self.wrappers;
    perSystem = {pkgs, ...}: {wrappers.pkgs = pkgs;};
  };
}
