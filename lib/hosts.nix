{
  lib ? import ((import ../npins).nixpkgs.outPath + "/lib"),
  fleetLib ? import ./fleet.nix {inherit lib;},
  featureLib ? import ./features.nix {inherit fleetLib lib;},
  packageLib ? import ./packages.nix {inherit lib;},
}: let
  inherit (lib) mapAttrs;

  mkHostModule = {
    fleet,
    hostName,
    host,
    sources,
  }: let
    user = fleet.users.${host.owner} // {name = host.owner;};
  in {
    imports = featureLib.modulesFor host.platform host.features;

    config = {
      nixpkgs.overlays = [packageLib.overlay];

      _module.args = {
        inherit fleet fleetLib host packageLib sources user;
      };

      assertions = [
        {
          assertion = host.platform == "nixos" || host.platform == "darwin";
          message = "host '${hostName}' has unsupported platform '${host.platform}'";
        }
        {
          assertion = featureLib.missingFeatures host.features == [];
          message = "host '${hostName}' references unknown features: ${builtins.concatStringsSep ", " (featureLib.missingFeatures host.features)}";
        }
        {
          assertion = featureLib.missingPlatformModules host.platform host.features == [];
          message = "host '${hostName}' references features without ${host.platform} modules: ${builtins.concatStringsSep ", " (featureLib.missingPlatformModules host.platform host.features)}";
        }
      ];
    };
  };

  mkNixosConfigurations = {
    fleet,
    sources,
  }: let
    evalConfig = import "${sources.nixpkgs.outPath}/nixos/lib/eval-config.nix";
  in
    mapAttrs (
      hostName: host: let
        user = fleet.users.${host.owner} // {name = host.owner;};
      in
        evalConfig {
          inherit (host) system;
          specialArgs = {
            inherit fleet fleetLib host packageLib sources user;
          };
          modules = [
            {
              nixpkgs.hostPlatform.system = host.system;
            }
            (mkHostModule {
              inherit fleet hostName host sources;
            })
          ];
        }
    )
    (fleetLib.platformHosts "nixos" fleet.hosts);

  mkDarwinConfigurations = {
    fleet,
    sources,
  }: let
    evalConfig = import (sources.darwin.outPath + "/eval-config.nix");
    nixpkgsLib = import (sources.nixpkgs.outPath + "/lib");
  in
    mapAttrs (
      hostName: host: let
        user = fleet.users.${host.owner} // {name = host.owner;};
      in
        evalConfig {
          lib = nixpkgsLib;
          specialArgs = {
            inherit fleet fleetLib host packageLib sources user;
          };
          modules = [
            {
              nixpkgs.hostPlatform.system = host.system;
              nixpkgs.source = sources.nixpkgs.outPath;
              nixpkgs.flake.source = sources.nixpkgs.outPath;
              system.checks.verifyNixPath = false;
            }
            (mkHostModule {
              inherit fleet hostName host sources;
            })
          ];
        }
    )
    (fleetLib.platformHosts "darwin" fleet.hosts);
in {
  inherit mkDarwinConfigurations mkHostModule mkNixosConfigurations;
}
