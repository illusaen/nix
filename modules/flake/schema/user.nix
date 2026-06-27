{
  lib,
  rootPath,
  ...
}: let
  inherit (lib) mkOption;
  inherit (lib.types) submodule nullOr path listOf int str bool;
  mkOptionWithoutReflection = option: mkOption option // {identity = false;};

  sshKeyType = submodule {
    options = {
      tag = mkOption {
        type = nullOr str;
        default = null;
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
      options.secretPath = mkOption {
        type = path;
        default = rootPath + "/secrets/users/${config.name}";
        description = "Per-user secret directory";
      };
      config.system.gid = with config.system;
        if gid == null
        then uid
        else gid;
    })
  ];
  schema.user.options = {
    identity = mkOption {
      type = submodule {
        options = {
          displayName = mkOption {
            type = str;
            default = "";
            description = "Display name for the user";
          };
          email = mkOption {
            type = nullOr str;
            default = null;
            description = "Email address for the user";
          };
          sshKeys = mkOptionWithoutReflection {
            type = listOf sshKeyType;
            default = [];
            description = "SSH public keys for the user, each with an optional tag";
          };
        };
      };
      default = {};
      description = "User identity information";
    };
    system = mkOptionWithoutReflection {
      type = submodule {
        options = {
          uid = mkOption {
            type = nullOr int;
            default = null;
            description = "User ID for the Unix account";
          };
          gid = mkOption {
            type = nullOr int;
            default = null;
            description = "Group ID for the Unix account";
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
