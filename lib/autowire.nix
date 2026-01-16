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
    ;
  inherit (builtins) readDir toString;

  # Helper: Filter and map attributes in one pass
  mapFilterAttrs = f: attrs: filterAttrs (_: v: v != null) (mapAttrs' f attrs);
  safeReadDir = dir: if pathExists dir then readDir dir else { };

  processDir =
    {
      dir,
      ...
    }:
    func:
    lib.pipe dir [
      (safeReadDir)
      (mapAttrs' (
        name: type:
        let
          isValidNixFile = type == "regular" && hasSuffix ".nix" name && name != "default.nix";
          isValidDir = type == "directory" && pathExists (dir + "/${name}/default.nix");
          prefix = replaceString "/" "-" (toString (baseNameOf dir));
          configName = removeSuffix ".nix" name;
        in
        if isValidNixFile || isValidDir then
          nameValuePair ("${prefix}-${configName}") (func name)
        else
          nameValuePair "" null
      ))
      (filterAttrs (_: v: v != null))
    ];

  # Derive system architecture from host configurations
  # - Darwin hosts are detected by presence in configurations/darwin/ (always aarch64-darwin)
  # - NixOS hosts default to x86_64-linux, with explicit exceptions for ARM hosts
  hostToSystem =
    { darwinDir }:
    hostname:
    let
      hasDarwinConfig =
        pathExists (darwinDir + "/${hostname}.nix") || pathExists (darwinDir + "/${hostname}/default.nix");
    in
    if hasDarwinConfig then
      "aarch64-darwin"
    else if hostname == "cloud" || hostname == "modi" then
      "aarch64-linux" # Oracle Cloud ARM instance
    else
      "x86_64-linux";

in
{
  # Discover and import modules from a directory
  # Each .nix file or directory becomes a module export
  discoverModules = { dir }@args: processDir args (name: import (dir + "/${name}"));

  # Discover overlays from a directory
  discoverOverlays =
    { dir, inputs }@args: processDir args (name: import (dir + "/${name}") { inherit inputs; });

  # Discover packages from a directory
  # Each .nix file should be callPackage-compatible
  discoverPackages =
    { dir, pkgs }@args: processDir args (name: pkgs.callPackage (dir + "/${name}") { });

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
        configPath = if isValidNixFile then dir + "/${name}" else dir + "/${name}";
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

      # For each user, get their host configurations
      userHostConfigs =
        let
          hostsDir = dir + "/hosts";
          hostFiles = safeReadDir hostsDir;
        in
        mapFilterAttrs (
          hostName: type:
          if type == "regular" && hasSuffix ".nix" hostName then
            let
              cleanHostName = removeSuffix ".nix" hostName;
              configPath = hostsDir + "/${hostName}";
              system = getSystem cleanHostName;
            in
            nameValuePair vars.name (
              inputs.home-manager.lib.homeManagerConfiguration {
                # pkgs = nixpkgs.legacyPackages.${system};
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
        ) hostFiles;
    in
    userHostConfigs;

  inherit hostToSystem;
}
