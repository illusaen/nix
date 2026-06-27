{
  flake.modules.generic.nix-settings = {
    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];
      abort-on-warn = false;
      accept-flake-config = true;
      auto-optimise-store = true;
      warn-dirty = false;
      use-xdg-base-directories = true;
      trusted-users = [
        "root"
        "@wheel"
      ];
      trusted-substituters = [
        "https://cache.nixos.org/"
        "https://cache.nixos-cuda.org"
        "https://nix-community.cachix.org"
        "https://nixpkgs-unfree.cachix.org"
        "https://illusaen.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
        "illusaen.cachix.org-1:fxa0K6z978YmVBWgy58TJp8qnw2XxWjC997ArJzzuxk="
      ];
    };

    nixpkgs.config.allowUnfree = true;

    time.timeZone = "America/Chicago";

    security.sudo.extraConfig = ''
      Defaults lecture = never
    '';
  };
}
