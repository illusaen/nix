{
  lib ? import ((import ../npins).nixpkgs.outPath + "/lib"),
  sources ? import ../npins,
  fleetLib ? import ./fleet.nix {inherit lib;},
  featureLib ? import ./features.nix {inherit lib;},
  hostLib ? import ./hosts.nix {inherit featureLib fleetLib lib;},
}: let
  inherit (lib) mapAttrs;

  ownerUser = fleet: host:
    fleet.users.${host.owner} // {name = host.owner;};

  mkHostEvalArgs = fleet: host: {
    inherit fleet fleetLib host sources;
    user = ownerUser fleet host;
  };
in {
  mkNixosConfigurations = {fleet}: let
    evalConfig = import "${sources.nixpkgs.outPath}/nixos/lib/eval-config.nix";
  in
    mapAttrs (
      hostName: host:
        evalConfig {
          inherit (host) system;
          specialArgs = mkHostEvalArgs fleet host;
          modules = [
            {
              nixpkgs.hostPlatform.system = host.system;
            }
            (hostLib.mkHostModule {
              inherit fleet hostName host sources;
            })
          ];
        }
    )
    (fleetLib.platformHosts "nixos" fleet.hosts);

  mkDarwinConfigurations = {fleet}: let
    evalConfig = import (sources.darwin.outPath + "/eval-config.nix");
    nixpkgsLib = import (sources.nixpkgs.outPath + "/lib");
  in
    mapAttrs (
      hostName: host:
        evalConfig {
          lib = nixpkgsLib;
          specialArgs = mkHostEvalArgs fleet host;
          modules = [
            {
              nixpkgs = {
                hostPlatform.system = host.system;
                source = sources.nixpkgs.outPath;
                flake.source = sources.nixpkgs.outPath;
              };
              system.checks.verifyNixPath = false;
            }
            (hostLib.mkHostModule {
              inherit fleet hostName host sources;
            })
          ];
        }
    )
    (fleetLib.platformHosts "darwin" fleet.hosts);
}
