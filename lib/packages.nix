{
  sources ? import ../npins,
  lib ? import (sources.nixpkgs.outPath + "/lib"),
}: let
  inherit (builtins) attrNames filter listToAttrs readDir;
  inherit (lib) pipe;

  packageRoot = ../packages;
  packageEntries = readDir packageRoot;
  packageNamesFrom = entries:
    pipe entries [
      attrNames
      (filter (
        name:
          entries.${name}
          == "directory"
          && builtins.pathExists (packageRoot + "/${name}/package.nix")
      ))
    ];
  packageNames = packageNamesFrom packageEntries;

  overlay = final: _prev: {
    local = pipe packageNames [
      (map (name: {
        inherit name;
        value = final.callPackage (packageRoot + "/${name}/package.nix") {};
      }))
      listToAttrs
    ];
  };
in {
  inherit overlay packageNames;
}
