{
  lib ? import ((import ../npins).nixpkgs.outPath + "/lib"),
  fleetLib ? import ./fleet.nix {inherit lib;},
  featureLib ? import ./features.nix {inherit lib;},
  packageLib ? import ./packages.nix {inherit lib;},
}: {
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
}
