{
  inputs,
  lib,
  ...
}: let
  inherit (lib) mkOption;
  inherit (lib.types) nullOr int bool;
  mkOptionWithoutReflection = option: mkOption option // {identity = false;};

  genSchema = inputs.gen-schema.lib;
in {
  schema.group.validators = [
    (genSchema.mkValidator "posix-needs-gid" ({
      isPosix,
      gid,
      ...
    }:
      !isPosix || gid != null) "groups with the 'posix' tag must have a gid set")
  ];
  schema.group.options = {
    gid = mkOption {
      type = nullOr int;
      default = null;
      description = "Group ID for the Unix account";
    };
    isPosix = mkOptionWithoutReflection {
      type = bool;
      default = false;
      description = "If the group is a system created group";
    };
    members = mkOption {
      type = genSchema.setOf (genSchema.ref "user");
      default = [];
      description = "Users who are in the group. Can also be assigned group names; members of the named group will also be members of this group";
    };
  };
}
