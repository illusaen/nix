let
  api = import ./default.nix;
  inherit (api) sources;
  hostLib = import ./lib/hosts.nix {
    inherit (api) featureLib fleetLib packageLib;
    lib = api.nixpkgsLib;
  };
  nixpkgs = import sources.nixpkgs.outPath {
    overlays = [api.packageLib.overlay];
  };
in
  {
    meta = {
      inherit nixpkgs;
      specialArgs = {
        inherit sources;
        inherit (api) fleet;
      };
    };
  }
  // builtins.mapAttrs (
    hostName: host: {
      imports = [
        (hostLib.mkHostModule {
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
