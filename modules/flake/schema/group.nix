{
  inputs,
  lib,
  ...
}: let
  inherit (lib) mkOption;
  inherit (lib.types) bool;
  mkOptionWithoutReflection = option: mkOption option // {identity = false;};

  genSchema = inputs.gen-schema.lib;
in {
  schema.group.options = {
    isPosix = mkOptionWithoutReflection {
      type = bool;
      default = false;
      description = "If the group maps to an existing POSIX system group";
    };
    members = mkOption {
      type = genSchema.setOf (genSchema.ref "user");
      default = [];
      description = "Users who are in the group. Can also be assigned group names; members of the named group will also be members of this group";
    };
  };
}
