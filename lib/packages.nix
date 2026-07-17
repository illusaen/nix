{lib ? import ((import ../npins).nixpkgs.outPath + "/lib")}: let
  inherit (builtins) attrNames filter listToAttrs readDir;
  inherit (lib) pipe;

  packageRoot = ../packages;
  packageEntries = readDir packageRoot;
  packageNames = pipe packageEntries [
    attrNames
    (filter (
      name:
        packageEntries.${name}
        == "directory"
        && builtins.pathExists (packageRoot + "/${name}/package.nix")
    ))
  ];

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
  inherit overlay;
}
