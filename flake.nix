{
  description = "Wendy's NixOS and nix-darwin fleet";

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos-cuda.org"
      "https://colmena.cachix.org"
      "https://nix-community.cachix.org"
      "https://nixpkgs-unfree.cachix.org"
      "https://illusaen.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      "colmena.cachix.org-1:7BzpDnjjH8ki2CT3f6GdOk7QAzPOl+1t3LvTLXqYcSg="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
      "illusaen.cachix.org-1:fxa0K6z978YmVBWgy58TJp8qnw2XxWjC997ArJzzuxk="
    ];
  };

  inputs = {
    agenix = {
      url = "github:ryantm/agenix/main";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.darwin.follows = "darwin";
    };
    base16.url = "github:SenchoPens/base16.nix/main";
    colmena = {
      url = "github:nix-community/colmena/v0.4.0";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.stable.follows = "nixpkgs";
    };
    darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devshell = {
      url = "github:numtide/devshell/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hjem = {
      url = "github:feel-co/hjem/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    noctalia = {
      url = "github:noctalia-dev/noctalia/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    preservation.url = "github:nix-community/preservation/main";
  };

  outputs = inputs @ {
    self,
    colmena,
    nixpkgs,
    ...
  }: let
    inherit (nixpkgs) lib;
    api = import ./lib/mk-api.nix {inherit inputs;};
    supportedSystems = import ./lib/supported-systems.nix;
    forAllSystems = lib.genAttrs supportedSystems;
    pkgsFor = system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [api.overlays];
      };
    devFor = system:
      import ./lib/mk-dev-shell.nix {
        inherit inputs system;
      };
    rawHive = import ./lib/mk-hive.nix {
      inherit api;
      system = "x86_64-linux";
    };
    hostPackagesFor = system:
      lib.mapAttrs' (
        name: configuration:
          lib.nameValuePair "system-${name}" configuration.config.system.build.toplevel
      )
      (lib.filterAttrs (
          name: _configuration: api.fleet.hosts.${name}.system == system
        )
        api.nixosConfigurations);
    packagesFor = system: let
      pkgs = pkgsFor system;
      localPackages = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux pkgs.local;
      cachePackages = lib.optionalAttrs (system == "x86_64-linux") {
        inherit (pkgs) bambu-studio;
        llama-cpp-cuda = api.nixosConfigurations.odin.config.services.llama-cpp.package;
      };
    in
      localPackages // hostPackagesFor system // cachePackages;
    checksFor = system: let
      pkgs = pkgsFor system;
      dev = devFor system;
      integration = import ./tests/integration.nix {
        inherit api pkgs;
        hive = rawHive;
        inherit (api) darwinConfigurations;
      };
      runtimeThemeCheck = lib.optionalAttrs (system == "x86_64-linux") {
        runtime-themes = import ./tests/runtime-themes.nix {
          inherit api lib pkgs;
        };
      };
    in
      {
        fleet = integration.evaluation;
        formatting =
          pkgs.runCommand "repository-formatting" {
            nativeBuildInputs = [dev.formatter];
          } ''
            cp -r ${self} source
            chmod -R u+w source
            cd source
            treefmt --fail-on-change
            touch $out
          '';
      }
      // runtimeThemeCheck;
  in {
    inherit (api) nixosConfigurations darwinConfigurations;

    colmenaHive = colmena.lib.makeHive rawHive;

    lib =
      api.libs
      // {
        inherit (api) fleet;
        inherit supportedSystems;
      };

    overlays.default = api.overlays;

    checks = forAllSystems checksFor;
    devShells = forAllSystems (system: {default = (devFor system).shell;});
    formatter = forAllSystems (system: (devFor system).formatter);
    packages = forAllSystems packagesFor;
  };
}
