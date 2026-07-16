let
  sources = import ../npins;
  nixpkgsLib = import (sources.nixpkgs.outPath + "/lib");
  fleetLib = import ../lib/fleet.nix {lib = nixpkgsLib;};
  featureLib = import ../lib/features.nix {
    inherit fleetLib;
    lib = nixpkgsLib;
  };
  serviceLib = import ../lib/services.nix {
    inherit fleetLib;
    lib = nixpkgsLib;
  };
  evalFleet = import ../lib/eval-fleet.nix {lib = nixpkgsLib;};

  baseFleet = {
    domain = "home.arpa";
    timeZone = "America/Chicago";
    users.wendy.groups = ["system-access"];
    groups = {
      system-access = {
        isPosix = false;
        members = [];
      };
      wheel = {
        isPosix = true;
        members = ["system-access"];
      };
      kvm = {
        isPosix = true;
        members = ["hardware-access"];
      };
      hardware-access = {
        isPosix = false;
        members = [];
      };
    };
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

  routedFleet = serviceLib.routeHosts baseFleet;
in {
  platformForSystem =
    fleetLib.platformForSystem "x86_64-linux"
    == "nixos"
    && fleetLib.platformForSystem "aarch64-darwin" == "darwin"
    && fleetLib.platformForSystem "wasm32-wasi" == null;

  validFleet = validationErrors baseFleet == [];

  userPosixGroups =
    fleetLib.userPosixGroups baseFleet "wendy" == ["wheel"];

  userPosixGroupsIgnoreUnmatched =
    fleetLib.userPosixGroups (testFleet {
      users.wendy.groups = ["unknown-nonvalidated"];
    })
    "wendy"
    == [];

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

  unknownUserGroup =
    hasError "user 'wendy' references unknown group 'missing'"
    (testFleet {
      users.wendy.groups = ["missing"];
    });

  duplicateUserGroup =
    hasError "user 'wendy' lists group 'system-access' more than once"
    (testFleet {
      users.wendy.groups = ["system-access" "system-access"];
      groups.system-access = {
        isPosix = false;
        members = [];
      };
    });

  unknownGroupMember =
    hasError "group 'wheel' references unknown member group 'missing'"
    (testFleet {
      groups.wheel = {
        isPosix = true;
        members = ["missing"];
      };
    });

  duplicateGroupMember =
    hasError "group 'wheel' lists member group 'system-access' more than once"
    (testFleet {
      groups = {
        system-access = {
          isPosix = false;
          members = [];
        };
        wheel = {
          isPosix = true;
          members = ["system-access" "system-access"];
        };
      };
    });

  duplicateUserUid =
    hasError "uid '1000' is used by multiple users"
    (testFleet {
      users = {
        wendy.system.uid = 1000;
        guest.system.uid = 1000;
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

  duplicateServiceBackup =
    hasError "service 'app' lists backup host 'huginn' more than once"
    (testFleet {
      services = {
        app =
          baseFleet.services.app
          // {
            backups = ["huginn" "huginn"];
          };
      };
    });

  routedPrimaryService =
    routedFleet.odin.services.app.role
    == "primary"
    && routedFleet.odin.services.app.port == 8080
    && builtins.elem "llama-cpp" routedFleet.odin.features;

  derivedLinuxBaseFeatures =
    builtins.elem "base" routedFleet.odin.features
    && builtins.elem "boot" routedFleet.odin.features;

  derivedDesktopFeatures = let
    fleet = testFleet {
      hosts.odin =
        baseFleet.hosts.odin
        // {
          tags = ["desktop" "gpu:nvidia" "feature:creative" "feature:dev"];
          preservation = {
            enable = true;
            disk = "nvme0n1";
          };
        };
    };
    routed = serviceLib.routeHosts fleet;
  in
    builtins.elem "programs-core" routed.odin.features
    && builtins.elem "theming" routed.odin.features
    && builtins.elem "desktop-shell" routed.odin.features
    && builtins.elem "nvidia" routed.odin.features
    && builtins.elem "programs-creative" routed.odin.features
    && builtins.elem "programs-dev" routed.odin.features
    && builtins.elem "preservation" routed.odin.features;

  derivedDarwinDesktopFeatures = let
    fleet = testFleet {
      hosts.macbook = {
        system = "aarch64-darwin";
        owner = "wendy";
        targetHost = "macbook.home.arpa";
        tags = ["desktop" "feature:dev"];
        preservation.enable = false;
      };
    };
    routed = serviceLib.routeHosts fleet;
  in
    builtins.elem "base" routed.macbook.features
    && builtins.elem "programs-core" routed.macbook.features
    && builtins.elem "theming" routed.macbook.features
    && builtins.elem "programs-dev" routed.macbook.features
    && !(builtins.elem "boot" routed.macbook.features)
    && !(builtins.elem "desktop-shell" routed.macbook.features);

  routedBackupService = let
    fleet = testFleet {
      services = {
        app =
          baseFleet.services.app
          // {
            backups = ["huginn"];
          };
      };
    };
    routed = serviceLib.routeHosts fleet;
  in
    routed.huginn.services.app.role
    == "backup"
    && builtins.elem "llama-cpp" routed.huginn.features;

  routedImplicitServiceFeature = let
    fleet = testFleet {
      services = {
        app = removeAttrs baseFleet.services.app ["feature"];
      };
    };
    routed = serviceLib.routeHosts fleet;
  in
    builtins.elem "app" routed.odin.features;

  normalizedHostDefaults =
    routedFleet.odin.platform
    == "nixos"
    && routedFleet.odin.name == "odin"
    && routedFleet.odin.privateKey == "/etc/ssh/host_ed25519"
    && toString routedFleet.odin.publicKey == toString (../secrets/hosts + "/odin/host_ed25519.pub")
    && routedFleet.odin.preservation.enable == false;

  evaluatedFleetDefaults = let
    evaluated = evalFleet baseFleet;
  in
    evaluated.hosts.odin.platform
    == "nixos"
    && evaluated.hosts.odin.name == "odin"
    && evaluated.hosts.odin.privateKey == "/etc/ssh/host_ed25519"
    && toString evaluated.hosts.odin.publicKey == toString (../secrets/hosts + "/odin/host_ed25519.pub")
    && evaluated.hosts.odin.preservation.rootSnapshot == "zroot/local/root@blank"
    && evaluated.hosts.odin.networkInterfaces.eno1.ipv6 == null
    && evaluated.users.wendy.system.isAdmin == false
    && evaluated.services.app.backups == []
    && evaluated.services.app.feature == "llama-cpp";

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

  routedServiceFeaturePlatformModuleErrors =
    featureLib.serviceFeaturePlatformModuleErrors
    (
      baseFleet.hosts
      // {
        macbook = {
          system = "aarch64-darwin";
          owner = "wendy";
          targetHost = "macbook.home.arpa";
          features = ["base"];
          preservation.enable = false;
        };
      }
    )
    {
      app =
        baseFleet.services.app
        // {
          primary = "macbook";
        };
    }
    == [
      "service 'app' feature 'llama-cpp' has no darwin module for host 'macbook'"
    ];
}
