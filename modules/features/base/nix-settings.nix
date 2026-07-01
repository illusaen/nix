{lib, ...}: {
  flake.moduleOptions.generic.nix-settings = {
    abortOnWarn = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether Nix should abort on warnings.";
    };
    warnDirty = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether Nix should warn about dirty Git trees.";
    };
    useXdgBaseDirectories = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether Nix should use XDG base directories.";
    };
  };

  flake.modules.generic.nix-settings = {
    fleet,
    moduleSettings,
    ...
  }: {
    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operator"
      ];
      abort-on-warn = moduleSettings.nix-settings.abortOnWarn;
      accept-flake-config = true;
      auto-optimise-store = true;
      warn-dirty = moduleSettings.nix-settings.warnDirty;
      use-xdg-base-directories = moduleSettings.nix-settings.useXdgBaseDirectories;
      trusted-users = [
        "root"
        "@wheel"
      ];
      extra-substituters = [
        "https://cache.nixos-cuda.org"
        "https://nix-community.cachix.org"
        "https://nixpkgs-unfree.cachix.org"
        "https://illusaen.cachix.org"
      ];
      extra-trusted-public-keys = [
        "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
        "illusaen.cachix.org-1:fxa0K6z978YmVBWgy58TJp8qnw2XxWjC997ArJzzuxk="
      ];
    };

    nixpkgs.config.allowUnfree = true;

    time.timeZone = fleet.timeZone;

    security.sudo.extraConfig = ''
      Defaults lecture = never
    '';
  };
}
