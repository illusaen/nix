{
  lib,
  inputs,
  fleetLib,
  hostLib,
}: let
  inherit (lib) mapAttrs;
in {
  mkNixosConfigurations = {fleet}:
    mapAttrs (
      _hostName: host:
        inputs.nixpkgs.lib.nixosSystem {
          inherit (host) system;
          modules = [
            (hostLib.mkHostModule {
              inherit fleet host inputs;
            })
          ];
        }
    )
    (fleetLib.platformHosts "nixos" fleet.hosts);

  mkDarwinConfigurations = {fleet}:
    mapAttrs (
      _hostName: host:
        inputs.darwin.lib.darwinSystem {
          inherit (host) system;
          modules = [
            (hostLib.mkHostModule {
              inherit fleet host inputs;
            })
          ];
        }
    )
    (fleetLib.platformHosts "darwin" fleet.hosts);
}
