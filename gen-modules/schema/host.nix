{
  lib,
  genSchema,
  ...
}: let
  inherit (lib) mkOption mkEnableOption;
  inherit (lib.types) either enum submodule path attrsOf listOf nullOr str;

  getIpFromInterface = isIpv4: interfaces: let
    version =
      if isIpv4
      then "ipv4"
      else "ipv6";
  in
    interfaces
    |> lib.attrValues
    |> builtins.filter (lib.hasAttr version)
    |> builtins.catAttrs version
    |> map (addr: builtins.head (lib.splitString "/" addr))
    |> (i:
      if i == []
      then null
      else builtins.head i);
in {
  schema.host.validators = [
    (genSchema.mkValidator "has-owner" ({owner, ...}: owner != null) "owner must not be null")
    (genSchema.mkValidator "has-ip" ({
      ipv4,
      ipv6,
      ...
    }:
      ipv4 != null || ipv6 != null) "host must have either a ipv4 or ipv6 address, or both")
    (genSchema.mkValidator "has-public-key" ({publicKey, ...}:
        publicKey != null && builtins.pathExists publicKey) "publicKey must exist and be a valid path")
    (genSchema.mkValidator "has-disk-if-preservation" ({preservation, ...}: !preservation.enable || preservation.disk != null) "if preservation is enabled then disk must not be null")
  ];

  schema.host.imports = [
    ({config, ...}: {
      config.class = lib.mkDefault (
        if lib.hasSuffix "-darwin" config.system
        then "darwin"
        else "nixos"
      );

      options.ipv4 = mkOption {
        type = str;
        readOnly = true;
        description = "Primary IPv4 address (derived from first interface with IPs, CIDR stripped)";
        default =
          getIpFromInterface true (config.networkInterfaces or {});
      };

      options.ipv6 = mkOption {
        type = str;
        readOnly = true;
        description = "Primary IPv6 address (derived from first interface with IPs, CIDR stripped)";
        default =
          getIpFromInterface false (config.networkInterfaces or {});
      };
    })
  ];
  schema.host.options = {
    system = lib.mkOption {
      type = enum ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
      description = "System platform";
    };

    class = lib.mkOption {
      type = enum ["nixos" "darwin"];
      readOnly = true;
      internal = true;
      description = "System configuration class used to build this host.";
    };

    networkInterfaces = mkOption {
      type = attrsOf (submodule {
        options = {
          ipv4 = mkOption {
            type = str;
            description = "IPv4 address in CIDR notation";
          };
          ipv6 = mkOption {
            type = str;
            description = "IPv6 address in CIDR notation";
          };
        };
      });
      default = {};
      defaultText = {text = "{}";};
      description = "Network interfaces";
    };

    owner = mkOption {
      type = genSchema.ref "user";
      description = "Primary user for this host";
    };

    hostId = mkOption {
      type = str;
      internal = true;
      description = "Used in networking.hostId for ZFS identification";
    };

    facter = mkOption {
      type = path;
      readOnly = true;
      internal = true;
      description = "Derived path to host facter.json";
    };

    publicKey = mkOption {
      type = path;
      description = "Derived path to this host's SSH public key.";
      readOnly = true;
    };

    privateKey = mkOption {
      type = path;
      description = "Path to this host's SSH private key.";
      readOnly = true;
      default = "/etc/ssh/host_ed25519";
    };

    tags = mkOption {
      type = attrsOf (either str (listOf str));
      description = "Host tags for organization and feature gates";
      default = {};
      defaultText = {text = "{}";};
    };

    monitors = mkOption {
      type = submodule {
        options = {
          main = mkOption {
            type = nullOr str;
            default = null;
            description = "Primary monitor connector.";
          };
          secondary = mkOption {
            type = nullOr str;
            default = null;
            description = "Secondary monitor connector.";
          };
        };
      };
      default = {};
      defaultText = {text = "{}";};
      description = "Host monitor connectors.";
    };

    moduleNames = mkOption {
      type = listOf str;
      default = [];
      apply = lib.unique;
      description = "Named flake modules that this host contributes to its system configuration.";
    };

    extraModule = mkOption {
      type = lib.types.deferredModule;
      default = {};
      defaultText = {text = "{}";};
      description = "Ad-hoc module that this host contributes to its system configuration.";
    };

    preservation = mkOption {
      type = submodule {
        options = {
          enable = mkEnableOption "Whether this host uses persistent state via preservation.";
          disk = mkOption {
            type = str;
            description = "Disk used in disko, the last part of /dev/disk. Note, NOT the partition, so if a disk is nvme0n1 with partitions nvme0n1p1 and nvme0n1p2, use nvme0n1.";
          };
          rootSnapshot = mkOption {
            type = str;
            description = "ZFS ephemeral snapshot used to wipe root";
            default = "zroot/local/root@blank";
          };
          homeSnapshot = mkOption {
            type = str;
            description = "ZFS ephemeral snapshot used to wipe home";
            default = "zroot/local/home@blank";
          };
          persistMount = mkOption {
            type = str;
            default = "/persist";
          };
        };
      };
    };
  };
}
