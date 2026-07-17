{
  lib,
  sources,
  fleetLib,
  hostLib,
}: let
  inherit (lib) mapAttrs;
in {
  mkNixosConfigurations = {fleet}: let
    evalConfig = import "${sources.nixpkgs.outPath}/nixos/lib/eval-config.nix";
  in
    mapAttrs (
      hostName: host:
        evalConfig {
          inherit (host) system;
          modules = [
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
          modules = [
            {
              nixpkgs = {
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
