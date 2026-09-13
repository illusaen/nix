{
  deployLib,
  fleet,
  hostLib,
  inputs,
  overlay,
  system,
}: let
  nixpkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [overlay];
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
        (hostLib.mkHostModule {
          inherit host inputs fleet;
        })
      ];

      deployment = {
        inherit (host) targetHost;
        targetUser = host.owner;
        buildOnTarget = false;
        tags = deployLib.deploymentTags host;
        allowLocalDeployment = true;
      };
    }
  )
  deployLib.nixosHosts
