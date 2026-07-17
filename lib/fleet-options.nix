{lib, ...}: let
  inherit (lib) mkOption types;

  sshKeyType = types.submodule {
    options = {
      tag = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Optional label for the SSH key.";
      };

      key = mkOption {
        type = types.str;
        description = "SSH public key.";
      };
    };
  };

  networkInterfaceType = types.submodule {
    options = {
      ipv4 = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "IPv4 address in CIDR notation.";
      };

      ipv6 = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "IPv6 address in CIDR notation.";
      };
    };
  };

  preservationType = types.submodule {
    options = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether this host uses persistent state via preservation.";
      };

      disk = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Disk used by disko when preservation is enabled.";
      };

      rootSnapshot = mkOption {
        type = types.str;
        default = "zroot/local/root@blank";
        description = "ZFS ephemeral snapshot used to wipe root.";
      };

      homeSnapshot = mkOption {
        type = types.str;
        default = "zroot/local/home@blank";
        description = "ZFS ephemeral snapshot used to wipe home.";
      };

      persistMount = mkOption {
        type = types.str;
        default = "/persist";
        description = "Mount point for persisted state.";
      };
    };
  };

  hostType = types.submodule ({
    name,
    config,
    ...
  }: {
    options = {
      name = mkOption {
        type = types.str;
        default = name;
        readOnly = true;
        description = "Fleet host name.";
      };

      system = mkOption {
        type = types.enum ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
        description = "Nix system identifier.";
      };

      platform = mkOption {
        type = types.enum ["nixos" "darwin"];
        default =
          if lib.hasSuffix "-darwin" config.system
          then "darwin"
          else "nixos";
        readOnly = true;
        description = "Host configuration platform derived from system.";
      };

      owner = mkOption {
        type = types.str;
        description = "Primary fleet user for this host.";
      };

      targetHost = mkOption {
        type = types.str;
        description = "SSH target or local deploy target for this host.";
      };

      hostId = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "NixOS networking.hostId value.";
      };

      privateKey = mkOption {
        type = types.str;
        default = "/etc/ssh/host_ed25519";
        description = "Path to this host's SSH private key.";
      };

      publicKey = mkOption {
        type = types.path;
        default = ../secrets/hosts + "/${name}/host_ed25519.pub";
        description = "Path to this host's SSH public key.";
      };

      features = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Manual feature names for this host.";
      };

      tags = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Host tags used for deploy selectors and derived features.";
      };

      networkInterfaces = mkOption {
        type = types.attrsOf networkInterfaceType;
        default = {};
        description = "Static network interfaces.";
      };

      monitors = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Named monitor connector mappings.";
      };

      preservation = mkOption {
        type = preservationType;
        default = {};
        description = "Preservation settings.";
      };

      services = mkOption {
        type = types.attrsOf types.attrs;
        default = {};
        description = "Services routed to this host.";
      };
    };
  });

  userType = types.submodule ({name, ...}: {
    options = {
      identity = mkOption {
        type = types.submodule {
          options = {
            displayName = mkOption {
              type = types.str;
              default = name;
              description = "Human-readable display name.";
            };

            accountName = mkOption {
              type = types.str;
              default = name;
              description = "External account name.";
            };

            email = mkOption {
              type = types.str;
              default = "";
              description = "User email address.";
            };

            sshKeys = mkOption {
              type = types.listOf sshKeyType;
              default = [];
              description = "SSH public keys for this user.";
            };
          };
        };
        default = {};
        description = "User identity metadata.";
      };

      groups = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Logical groups this user belongs to.";
      };

      system = mkOption {
        type = types.submodule {
          options = {
            uid = mkOption {
              type = types.nullOr types.int;
              default = null;
              description = "Unix user id.";
            };

            isAdmin = mkOption {
              type = types.bool;
              default = false;
              description = "Whether this user should have administrative access.";
            };
          };
        };
        default = {};
        description = "System account settings.";
      };
    };
  });

  groupType = types.submodule {
    options = {
      isPosix = mkOption {
        type = types.bool;
        default = false;
        description = "Whether this group maps to a POSIX group.";
      };

      members = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "User group names included in this group.";
      };
    };
  };

  serviceType = types.submodule ({name, ...}: {
    options = {
      name = mkOption {
        type = types.str;
        default = name;
        description = "Service name";
        readOnly = true;
      };

      feature = mkOption {
        type = types.str;
        default = name;
        description = "Feature enabled by this service.";
      };

      primary = mkOption {
        type = types.str;
        description = "Primary host for this service.";
      };

      backups = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Backup hosts for this service.";
      };

      port = mkOption {
        type = types.port;
        description = "Service port.";
      };

      protocol = mkOption {
        type = types.enum ["tcp" "udp" "http" "https"];
        default = "tcp";
        description = "Service network protocol.";
      };
    };
  });
in {
  options.fleet = {
    domain = mkOption {
      type = types.str;
      description = "Base domain for the fleet.";
    };

    timeZone = mkOption {
      type = types.str;
      default = "America/Chicago";
      description = "Default timezone for the fleet.";
    };

    hosts = mkOption {
      type = types.attrsOf hostType;
      default = {};
      description = "Fleet hosts.";
    };

    users = mkOption {
      type = types.attrsOf userType;
      default = {};
      description = "Fleet users.";
    };

    groups = mkOption {
      type = types.attrsOf groupType;
      default = {};
      description = "Fleet groups.";
    };

    services = mkOption {
      type = types.attrsOf serviceType;
      default = {};
      description = "Fleet services.";
    };

    fonts = mkOption {
      type = types.attrs;
      default = {};
      description = "Fleet font settings.";
    };

    theming = mkOption {
      type = types.attrs;
      default = {};
      description = "Fleet theming settings.";
    };

    themes = mkOption {
      type = types.attrs;
      default = {};
      description = "Runtime theme profiles.";
    };

    base16 = mkOption {
      type = types.attrs;
      default = {};
      description = "Default base16 theme settings.";
    };

    wallpaper = mkOption {
      type = types.attrs;
      default = {};
      description = "Default wallpaper settings.";
    };
  };
}
