let
  fleetLib = import ../lib/fleet.nix {};
  serviceLib = import ../lib/services.nix {inherit fleetLib;};

  baseFleet = {
    users.wendy = {};
    groups = {};
    hosts = {
      odin = {
        system = "x86_64-linux";
        owner = "wendy";
        targetHost = "odin.home.arpa";
        hostId = "abf835ae";
        features = ["base"];
        tags = ["desktop"];
        networkInterfaces.eno1.ipv4 = "192.168.1.162/24";
        preservation.enable = false;
      };

      huginn = {
        system = "x86_64-linux";
        owner = "wendy";
        targetHost = "huginn.home.arpa";
        hostId = "d0924987";
        features = ["base"];
        tags = ["server"];
        networkInterfaces.eno1.ipv4 = "192.168.1.164/24";
        preservation.enable = false;
      };
    };
    services = {
      app = {
        feature = "llama-cpp";
        primary = "odin";
        backups = [];
        port = 8080;
        protocol = "http";
      };
    };
  };

  validationErrors = fleet: fleetLib.validate fleet;

  hasError = expected: fleet:
    builtins.elem expected (validationErrors fleet);

  testFleet = patch:
    baseFleet // patch;
in {
  platformForSystem =
    fleetLib.platformForSystem "x86_64-linux"
    == "nixos"
    && fleetLib.platformForSystem "aarch64-darwin" == "darwin"
    && fleetLib.platformForSystem "wasm32-wasi" == null;

  validFleet = validationErrors baseFleet == [];

  duplicateFeature =
    hasError "host 'odin' lists feature 'base' more than once"
    (testFleet {
      hosts =
        baseFleet.hosts
        // {
          odin =
            baseFleet.hosts.odin
            // {
              features = ["base" "base"];
            };
        };
    });

  duplicateTag =
    hasError "host 'odin' lists tag 'desktop' more than once"
    (testFleet {
      hosts =
        baseFleet.hosts
        // {
          odin =
            baseFleet.hosts.odin
            // {
              tags = ["desktop" "desktop"];
            };
        };
    });

  duplicateTargetHost =
    hasError "targetHost 'odin.home.arpa' is used by multiple hosts"
    (testFleet {
      hosts =
        baseFleet.hosts
        // {
          huginn =
            baseFleet.hosts.huginn
            // {
              targetHost = "odin.home.arpa";
            };
        };
    });

  duplicateHostId =
    hasError "hostId 'abf835ae' is used by multiple hosts"
    (testFleet {
      hosts =
        baseFleet.hosts
        // {
          huginn =
            baseFleet.hosts.huginn
            // {
              hostId = "abf835ae";
            };
        };
    });

  duplicateNetworkAddress =
    hasError "network address '192.168.1.162/24' is used by multiple hosts"
    (testFleet {
      hosts =
        baseFleet.hosts
        // {
          huginn =
            baseFleet.hosts.huginn
            // {
              networkInterfaces.eno1.ipv4 = "192.168.1.162/24";
            };
        };
    });

  duplicateLinkLocalIpv6Allowed =
    validationErrors (testFleet {
      hosts = {
        odin =
          baseFleet.hosts.odin
          // {
            networkInterfaces.eno1 = {
              ipv4 = "192.168.1.162/24";
              ipv6 = "fe80::1/64";
            };
          };
        huginn =
          baseFleet.hosts.huginn
          // {
            networkInterfaces.eno1 = {
              ipv4 = "192.168.1.164/24";
              ipv6 = "fe80::1/64";
            };
          };
      };
    })
    == [];

  unsupportedSystem =
    hasError "host 'odin' has unsupported system 'wasm32-wasi'"
    (testFleet {
      hosts =
        baseFleet.hosts
        // {
          odin =
            baseFleet.hosts.odin
            // {
              system = "wasm32-wasi";
            };
        };
    });

  servicePortConflicts =
    serviceLib.portConflicts (testFleet {
      services =
        baseFleet.services
        // {
          other = {
            feature = "navidrome";
            primary = "odin";
            backups = [];
            port = 8080;
            protocol = "http";
          };
        };
    })
    == [
      {
        hostName = "odin";
        key = "odin:tcp:8080";
        services = ["app" "other"];
      }
    ];
}
