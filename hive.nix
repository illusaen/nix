let
  api = import ./default.nix;
  inherit (api) sources overlays fleet;
  deploymentTags = host:
    ["nixos"] ++ builtins.filter (tag: tag == "desktop" || tag == "server") (host.tags or []);
  nixpkgs =
    import sources.nixpkgs.outPath {
      system = builtins.currentSystem;
      overlays = [overlays];
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
        (api.libs.hostLib.mkHostModule {
          inherit hostName host sources fleet;
        })
      ];

      deployment = {
        inherit (host) targetHost;
        targetUser = host.owner;
        buildOnTarget = false;
        tags = deploymentTags host;
      };
    }
  )
  api.libs.deployLib.nixosHosts
