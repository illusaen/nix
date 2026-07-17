let
  api = import ./default.nix;
  inherit (api) sources;
  nixpkgs = import sources.nixpkgs.outPath {
    overlays = [api.packageLib.overlay];
  };
in
  {
    meta = {
      inherit nixpkgs;
    };
  }
  // builtins.mapAttrs (
    hostName: host: {
      imports = [
        (api.hostLib.mkHostModule {
          inherit hostName host sources;
          inherit (api) fleet;
        })
      ];

      deployment = {
        inherit (host) targetHost;
        targetUser = host.owner;
        buildOnTarget = false;
      };

      networking.hostName = hostName;
      nixpkgs.hostPlatform.system = host.system;
    }
  )
  api.deploy.nixosHosts
