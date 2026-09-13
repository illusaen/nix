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
    base16 = {
      url = "github:SenchoPens/base16.nix/main";
    };
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
    preservation = {
      url = "github:nix-community/preservation/main";
    };
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
      odinSystemPackages = api.nixosConfigurations.odin.config.environment.systemPackages;
      packageNamed = name:
        lib.findFirst
        (package: (package.pname or package.name or "") == name)
        (throw "Odin system package '${name}' was not found")
        odinSystemPackages;
      runtimeThemeCheck = lib.optionalAttrs (system == "x86_64-linux") {
        runtime-themes = let
          themeApply = packageNamed "theme-apply";
          themeProfiles = packageNamed "nix-theme-profiles";
          profileChecks = lib.concatMapStringsSep "\n" (
            name: ''
              test -f ${themeProfiles}/${lib.escapeShellArg name}/niri-colors.kdl
              if grep -q '@base' ${themeProfiles}/${lib.escapeShellArg name}/niri-colors.kdl; then
                echo "unresolved Niri color placeholder in theme profile: ${name}" >&2
                exit 1
              fi
            ''
          ) (builtins.attrNames api.fleet.themes.profiles);
        in
          pkgs.runCommand "runtime-theme-checks" {
            nativeBuildInputs = [pkgs.gnugrep themeApply];
          } ''
            ${profileChecks}

            export HOME="$TMPDIR/home"
            export XDG_STATE_HOME="$TMPDIR/state"
            export NIX_THEME_PROFILE_DIR="$TMPDIR/profiles"
            profile="$NIX_THEME_PROFILE_DIR/test"

            mkdir -p "$HOME" "$profile/gtk-3.0" "$profile/gtk-4.0" "$profile/qt5ct" "$profile/qt6ct"
            printf '%s\n' \
              'COLOR_SCHEME=default' \
              'GTK_THEME=test' \
              'ICON_THEME=test' \
              'CURSOR_THEME=test' \
              'CURSOR_SIZE=24' \
              > "$profile/env"
            printf '%s\n' 'test-niri-colors' > "$profile/niri-colors.kdl"
            touch "$profile/gtk-3.0/settings.ini" "$profile/qt5ct/qt5ct.conf" "$profile/qt6ct/qt6ct.conf"

            theme-apply test

            test "$(readlink "$XDG_STATE_HOME/nix-theme/current")" = "$profile"
            test "$(readlink "$XDG_STATE_HOME/nix-theme/niri-colors.kdl")" = "$XDG_STATE_HOME/nix-theme/current/niri-colors.kdl"
            test "$(cat "$XDG_STATE_HOME/nix-theme/niri-colors.kdl")" = 'test-niri-colors'
            touch $out
          '';
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
