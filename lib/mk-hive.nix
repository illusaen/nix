{
  api,
  system,
}: let
  inherit (api) inputs overlays fleet;
  nixpkgs =
    import inputs.nixpkgs {
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
          inherit host inputs fleet;
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
