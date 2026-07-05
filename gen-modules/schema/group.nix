{lib, ...}: let
  inherit (lib) mkOption;
  inherit (lib.types) bool listOf str;
  mkOptionWithoutReflection = option: mkOption option // {identity = false;};
in {
  schema.group.options = {
    isPosix = mkOptionWithoutReflection {
      type = bool;
      default = false;
      description = "If the group maps to an existing POSIX system group";
    };
    members = mkOption {
      type = listOf str;
      default = [];
      apply = lib.unique;
      description = "User or group names that belong to this group.";
    };
  };
}
