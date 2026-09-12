{
  api,
  system,
}: let
  inherit (api) sources overlays fleet;
  nixpkgs =
    import sources.nixpkgs.outPath {
      inherit system;
      overlays = [overlays];
    }
    // {
      inherit system;
    };
in
  {
    meta = {
      inherit nixpkgs;
    };
  }
  // builtins.mapAttrs (
    _hostName: host: {
      imports = [
        (api.libs.hostLib.mkHostModule {
          inherit host sources fleet;
        })
      ];

      deployment = {
        inherit (host) targetHost;
        targetUser = host.owner;
        buildOnTarget = false;
        tags = api.libs.deployLib.deploymentTags host;
        allowLocalDeployment = true;
      };
    }
  )
  api.libs.deployLib.nixosHosts
