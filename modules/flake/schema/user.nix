{
  inputs,
  lib,
  ...
}: let
  inherit (lib) mkOption;
  inherit (lib.types) submodule nullOr path listOf int str bool attrsOf anything;
  genSchema = inputs.gen-schema.lib;
  sshKeyType = submodule {
    options = {
      tag = mkOption {
        type = nullOr str;
        description = "Tag to categorize the SSH key (e.g., 'laptop', 'workstation', 'yubikey')";
      };
      key = mkOption {
        type = str;
        description = "SSH public key string";
      };
    };
  };
in {
  schema.user.imports = [
    ({config, ...}: {
      options.system.gid = mkOption {
        type = nullOr int;
        default = config.system.uid;
        description = "Group ID for the Unix account";
      };

      options.resolvedGroups = mkOption {
        type = genSchema.setOf (genSchema.ref "group");
        readOnly = true;
        description = "Computed set of group instances using group registry";
        default = config.groups;
      };
    })
  ];
  schema.user.options = {
    identity = mkOption {
      type = submodule {
        options = {
          displayName = mkOption {
            type = str;
            description = "Display name for the user";
          };
          accountName = mkOption {
            type = str;
            description = "Account name for the user";
          };
          email = mkOption {
            type = str;
            description = "Email address for the user";
          };
          sshKeys = mkOption {
            type = listOf sshKeyType;
            default = [];
            description = "SSH public keys for the user, each with an optional tag";
          };
        };
      };
      default = {};
      description = "User identity information";
    };

    secretPath = mkOption {
      type = path;
      readOnly = true;
      internal = true;
      description = "Per-user secret directory";
    };

    groups = mkOption {
      type = listOf str;
      description = "List of groups the user belongs to, with names from the group registry";
      default = [];
      apply = lib.unique;
    };

    moduleSettings = mkOption {
      type = attrsOf anything;
      default = {};
      description = "User-level raw module settings overrides.";
    };

    system = mkOption {
      type = submodule {
        options = {
          uid = mkOption {
            type = nullOr int;
            description = "User ID for the Unix account";
          };
          isAdmin = mkOption {
            type = bool;
            default = false;
            description = "If user has admin privileges";
          };
        };
      };
    };
  };
}
