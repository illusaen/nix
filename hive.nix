let
  api = import ./default.nix;
  inherit (api) sources;
  nixpkgs =
    import sources.nixpkgs.outPath {
      system = builtins.currentSystem;
      overlays = [api.packageOverlay];
    }
    // {
      system = builtins.currentSystem;
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
        (api.mkHostModule {
          inherit hostName host sources;
          inherit (api) fleet;
        })
      ];

      deployment = {
        inherit (host) targetHost;
        targetUser = host.owner;
        buildOnTarget = false;
      };
    }
  )
  api.deploy.nixosHosts
