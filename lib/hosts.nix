{
  featureLib ? import ./features.nix {},
  fleetLib ? import ./fleet.nix {},
  packageLib ? import ./packages.nix {},
}: let
  inherit (builtins) mapAttrs;

  mkHostModule = {
    fleet,
    hostName,
    host,
    sources,
  }: {
    imports = featureLib.modulesFor host.platform host.features;

    config = {
      nixpkgs.overlays = [packageLib.overlay];

      _module.args = {
        inherit fleet fleetLib host packageLib sources;
        user = fleet.users.${host.owner};
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
      hostName: host:
        evalConfig {
          inherit (host) system;
          specialArgs = {
            inherit fleet fleetLib host packageLib sources;
            user = fleet.users.${host.owner};
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
    darwin = import sources.darwin.outPath;
  in
    mapAttrs (
      hostName: host:
        darwin.lib.darwinSystem {
          inherit (host) system;
          specialArgs = {
            inherit fleet fleetLib host packageLib sources;
            user = fleet.users.${host.owner};
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
    (fleetLib.platformHosts "darwin" fleet.hosts);
in {
  inherit mkDarwinConfigurations mkHostModule mkNixosConfigurations;
}
