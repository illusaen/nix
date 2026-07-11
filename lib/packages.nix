{
  sources ? import ../npins,
  systems ? [
    "x86_64-linux"
    "aarch64-linux"
    "aarch64-darwin"
  ],
}: let
  inherit (builtins) attrNames filter listToAttrs readDir;

  packageRoot = ../packages;
  packageNames =
    filter (
      name:
        (readDir packageRoot).${name}
        == "directory"
        && builtins.pathExists (packageRoot + "/${name}/package.nix")
    )
    (attrNames (readDir packageRoot));

  optionalAttrs = condition: attrs:
    if condition
    then attrs
    else {};

  overlay = final: _prev: let
    packageArgs = name:
      optionalAttrs (name == "niri-scripts") {
        local = localPackages;
      };

    repoPackages = listToAttrs (
      map (name: {
        inherit name;
        value = final.callPackage (packageRoot + "/${name}/package.nix") (packageArgs name);
      })
      packageNames
    );

    localPackages =
      repoPackages
      // optionalAttrs (final ? niri) {
        inherit (final) niri;
      };
  in
    repoPackages
    // {
      local = localPackages;
    };

  packagesFor = system: let
    pkgs = import sources.nixpkgs.outPath {
      inherit system;
      config.allowUnfree = true;
      overlays = [overlay];
    };
  in
    listToAttrs (
      map (name: {
        inherit name;
        value = pkgs.${name};
      })
      packageNames
    );

  packages = listToAttrs (
    map (system: {
      name = system;
      value = packagesFor system;
    })
    systems
  );
in {
  inherit overlay packageNames packages packagesFor;
}
