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
      flake = false;
    };
    base16 = {
      url = "github:SenchoPens/base16.nix/main";
      flake = false;
    };
    colmena = {
      url = "github:nix-community/colmena/v0.4.0";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.stable.follows = "nixpkgs";
    };
    darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      flake = false;
    };
    devshell = {
      url = "github:numtide/devshell/main";
      flake = false;
    };
    disko = {
      url = "github:nix-community/disko/master";
      flake = false;
    };
    fromYaml = {
      url = "github:SenchoPens/fromYaml/main";
      flake = false;
    };
    hjem = {
      url = "github:feel-co/hjem/main";
      flake = false;
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    noctalia = {
      url = "github:noctalia-dev/noctalia/main";
      flake = false;
    };
    preservation = {
      url = "github:nix-community/preservation/main";
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    colmena,
    nixpkgs,
    ...
  }: let
    inherit (nixpkgs) lib;
    sources = {
      inherit
        (inputs)
        agenix
        base16
        darwin
        devshell
        disko
        fromYaml
        hjem
        nixpkgs
        noctalia
        preservation
        ;
    };
    api = import ./lib/mk-api.nix {inherit sources;};
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
    forAllSystems = lib.genAttrs supportedSystems;
    pkgsFor = system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [api.overlays];
      };
    devFor = system:
      import ./lib/mk-dev-shell.nix {
        inherit sources system;
        colmenaPackage = colmena.packages.${system}.colmena;
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
      ci = import ./ci.nix {
        inherit api pkgs;
        hive = rawHive;
        inherit (api) darwinConfigurations;
      };
    in {
      fleet = ci.plain-eval;
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
    };
  in {
    inherit (api) nixosConfigurations darwinConfigurations;

    colmenaHive = colmena.lib.makeHive rawHive;

    lib = api.libs // {inherit (api) fleet;};

    overlays.default = api.overlays;

    checks = forAllSystems checksFor;
    devShells = forAllSystems (system: {default = (devFor system).shell;});
    formatter = forAllSystems (system: (devFor system).formatter);
    packages = forAllSystems packagesFor;
  };
}
