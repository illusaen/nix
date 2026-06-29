{
  lib,
  inputs,
  ...
}: let
  inherit (lib) mkOption mkEnableOption;
  inherit (lib.types) enum submodule nullOr path attrsOf listOf str anything;
  genSchema = inputs.gen-schema.lib;

  mkOptionWithoutReflection = option: mkOption option // {identity = false;};
  mkStrListOption = description:
    mkOption {
      type = listOf str;
      default = [];
      inherit description;
    };
in {
  schema.host.imports = [
    ({config, ...}: {
      config.class = lib.mkDefault (
        if lib.hasSuffix "-darwin" config.system
        then "darwin"
        else "nixos"
      );

      options.ipv4 = mkOption {
        type = listOf str;
        readOnly = true;
        description = "Primary IPv4 addresses (derived from first interface with IPs, CIDR stripped)";
        default = let
          stripCidr = addr: builtins.head (lib.splitString "/" addr);
        in
          config.networkInterfaces or {}
          |> lib.attrValues
          |> lib.findFirst (i: i ? ipv4) null
          |> (i:
            if i != null
            then map stripCidr i.ipv4
            else []);
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
      description = "System configuration class used to build this host.";
    };

    networkInterfaces = mkOptionWithoutReflection {
      type = attrsOf (submodule {
        options = {
          ipv4 = mkStrListOption "IPv4 addresses in CIDR notation";
          ipv6 = mkStrListOption "IPv6 addresses in CIDR notation";
        };
      });
      default = {};
      description = "Network interfaces";
    };

    owner = mkOption {
      type = genSchema.ref "user";
      description = "Primary user for this host";
    };

    facts = mkOptionWithoutReflection {
      type = nullOr path;
      default = null;
    };

    secretPath = mkOptionWithoutReflection {
      type = nullOr path;
      default = null;
    };

    publicKey = mkOptionWithoutReflection {
      type = nullOr path;
      default = null;
    };

    tags = mkOption {
      type = attrsOf str;
      default = {};
      description = "Host tags for organization and feature gates";
    };

    settings = mkOption {
      type = attrsOf anything;
      default = {};
      description = "Host-level raw module settings overrides.";
    };

    moduleNames = mkOption {
      type = listOf str;
      default = [];
      apply = lib.unique;
      description = "Named flake modules that this host contributes to its system configuration.";
    };

    extraModule = mkOptionWithoutReflection {
      type = lib.types.deferredModule;
      default = {};
      description = "Ad-hoc module that this host contributes to its system configuration.";
    };

    preservation = mkOptionWithoutReflection {
      type = submodule {
        options = {
          enable = mkEnableOption "Whether this host uses persistent state via preservation.";
          disk = mkOption {
            type = str;
          };
          rollbackSnapshot = mkOption {
            type = str;
            default = "zroot/local/root@blank";
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
