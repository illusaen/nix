{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = lib.pipe (builtins.readDir ./.) [
    (lib.filterAttrs (
      name: type: type == "regular" && lib.strings.hasSuffix ".nix" name && name != "default.nix"
    ))
    (builtins.attrNames)
    (map (name: ./. + "/${name}"))
  ];
}
