{lib, ...}: let
  inherit (lib) mkOption;
  inherit (lib.types) submodule nullOr listOf int str bool;
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
      options.resolvedGroups = mkOption {
        type = listOf str;
        description = "Computed group names, including groups that directly or transitively include this user";
        default = config.groups;
        apply = lib.unique;
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
      defaultText = {text = "{}";};
      description = "User identity information";
    };

    groups = mkOption {
      type = listOf str;
      description = "List of groups the user belongs to, with names from the group registry";
      default = [];
      apply = lib.unique;
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
