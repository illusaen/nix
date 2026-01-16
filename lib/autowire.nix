# Autowiring helper functions for auto-discovering configurations and modules
{ lib, vars }:

let
  inherit (lib)
    pipe
    filterAttrs
    mapAttrs'
    nameValuePair
    hasSuffix
    removeSuffix
    attrNames
    pathExists
    concatMapAttrs
    elem
    replaceString
    splitString
    ;
  inherit (builtins) readDir toString;

  # Helper: Filter and map attributes in one pass
  mapFilterAttrs = f: attrs: filterAttrs (_: v: v != null) (mapAttrs' f attrs);
  safeReadDir = dir: if pathExists dir then readDir dir else { };

  processDirFn =
    dir: func: name: type:
    let
      isValidNixFile = type == "regular" && hasSuffix ".nix" name && name != "default.nix";
      isValidDir = type == "directory" && pathExists (dir + "/${name}/default.nix");
      prefix =
        if elem "modules" (splitString "/" dir) then (replaceString "/" "-" (baseNameOf dir)) + "-" else "";
      configName = removeSuffix ".nix" name;
    in
    if isValidNixFile || isValidDir then
      nameValuePair ("${prefix}${configName}") (func name)
    else
      nameValuePair "" null;

  processDir =
    dir: func:
    lib.pipe dir [
      (safeReadDir)
      (mapAttrs' (processDirFn dir func))
      (filterAttrs (_: v: v != null))
    ];

  hostToSystem =
    { darwinDir }:
    hostname:
    let
      hasDarwinConfig =
        pathExists (darwinDir + "/${hostname}.nix") || pathExists (darwinDir + "/${hostname}/default.nix");
    in
    if hasDarwinConfig then
      "aarch64-darwin"
    else if hostname == "modi" then
      "aarch64-linux" # Raspberry pi
    else
      "x86_64-linux";
in
{
  # Discover and import modules from a directory
  # Each .nix file or directory becomes a module export
  discoverModules = { dir }: processDir dir (name: import (dir + "/${name}"));

  # Discover overlays from a directory
  discoverOverlays =
    { dir, inputs }: processDir dir (name: import (dir + "/${name}") { inherit inputs; });

  # Discover packages from a directory
  # Each .nix file should be callPackage-compatible
  discoverPackages =
    {
      dir,
      pkgs,
      outputs,
    }:
    processDir dir (name: pkgs.callPackage (dir + "/${name}") { inherit outputs; });

  # Discover NixOS configurations
  # configurations/nixos/hostname/ -> nixosConfigurations.hostname
  # Note: Each host config should set nixpkgs.hostPlatform to define its architecture
  discoverNixosConfigurations =
    {
      dir,
      inputs,
      outputs,
      nixosModules,
      specialArgs ? { },
    }:
    mapFilterAttrs (
      name: type:
      let
        isValidNixFile = type == "regular" && hasSuffix ".nix" name && name != "default.nix";
        isValidDir = type == "directory" && pathExists (dir + "/${name}/default.nix");
        configName = removeSuffix ".nix" name;
        configPath = if isValidNixFile then dir + "/${name}" else dir + "/${name}";
      in
      if isValidNixFile || isValidDir then
        nameValuePair configName (
          inputs.nixpkgs.lib.nixosSystem {
            # System is determined by nixpkgs.hostPlatform in each host's config
            modules = [
              configPath
              # Import all discovered NixOS modules
              { imports = builtins.attrValues nixosModules; }
            ];
            specialArgs = specialArgs // {
              inherit inputs outputs;
            };
          }
        )
      else
        nameValuePair "" null
    ) (safeReadDir dir);

  # Discover Darwin configurations
  # configurations/darwin/hostname.nix -> darwinConfigurations.hostname
  discoverDarwinConfigurations =
    {
      dir,
      inputs,
      outputs,
      darwinModules,
      specialArgs ? { },
    }:
    mapFilterAttrs (
      name: type:
      let
        isValidNixFile = type == "regular" && hasSuffix ".nix" name && name != "default.nix";
        isValidDir = type == "directory" && pathExists (dir + "/${name}/default.nix");
        configName = removeSuffix ".nix" name;
        configPath = dir + "/${name}";
      in
      if isValidNixFile || isValidDir then
        nameValuePair configName (
          inputs.nix-darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            modules = [
              configPath
              # Import all discovered Darwin modules
              { imports = builtins.attrValues darwinModules; }
            ];
            specialArgs = specialArgs // {
              inherit inputs outputs;
            };
          }
        )
      else
        nameValuePair "" null
    ) (safeReadDir dir);

  # Discover Home Manager configurations
  # users/<user>/hosts/<host>.nix -> homeConfigurations."user@host"
  discoverHomeConfigurations =
    {
      dir,
      darwinDir,
      inputs,
      outputs,
      homeModules,
      extraSpecialArgs ? { },
    }:
    let
      nixpkgs = inputs.nixpkgs;
      getSystem = hostToSystem { inherit darwinDir; };

      # Get all user directories
      userDirs = filterAttrs (_: type: type == "directory") (safeReadDir dir);

      # For each user, get their host configurations
      userHostConfigs = concatMapAttrs (
        userName: _:
        let
          hostsDir = dir + "/${userName}/hosts";
          hostFiles = safeReadDir hostsDir;
        in
        mapFilterAttrs (_: v: v != null) (
          hostName: type:
          if type == "regular" && hasSuffix ".nix" hostName then
            let
              cleanHostName = removeSuffix ".nix" hostName;
              configName = "${userName}@${cleanHostName}";
              configPath = hostsDir + "/${hostName}";
              system = getSystem cleanHostName;
            in
            nameValuePair configName (
              inputs.home-manager.lib.homeManagerConfiguration {
                pkgs = nixpkgs.legacyPackages.${system};
                modules = [
                  configPath
                  # Import all discovered home modules
                  { imports = builtins.attrValues homeModules; }
                ];
                extraSpecialArgs = extraSpecialArgs // {
                  inherit inputs outputs;
                };
              }
            )
          else
            nameValuePair "" null
        ) hostFiles
      ) userDirs;
    in
    userHostConfigs;

  inherit hostToSystem;
}
