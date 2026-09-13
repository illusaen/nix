{
  inputs,
  fleetLib,
  hostLib,
}: let
  mkConfigurations = platform: buildConfiguration: {fleet}:
    builtins.mapAttrs (
      _hostName: host:
        buildConfiguration {
          inherit (host) system;
          modules = [
            (hostLib.mkHostModule {
              inherit fleet host inputs;
            })
          ];
        }
    )
    (fleetLib.platformHosts platform fleet.hosts);
in {
  mkNixosConfigurations = mkConfigurations "nixos" inputs.nixpkgs.lib.nixosSystem;
  mkDarwinConfigurations = mkConfigurations "darwin" inputs.darwin.lib.darwinSystem;
}
