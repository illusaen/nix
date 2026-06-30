# DO-NOT-EDIT. This file was auto-generated using github:vic/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{
  outputs = inputs: let
    evaluation = inputs.flake-parts.lib.evalFlakeModule {inherit inputs;} {
      imports = [((import inputs.import-tree) ./modules)];
      _module.args.rootPath = ./.;
    };
  in
    {inherit evaluation;} // evaluation.config.processedFlake;

  nixConfig = {
    experimental-features = ["nix-command" "flakes" "pipe-operators" "pipe-operator"];
    lazy-trees = true;
  };

  inputs = {
    base16.url = "github:SenchoPens/base16.nix";
    codex-desktop-linux = {
      url = "github:ilysenko/codex-desktop-linux";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    files = {
      url = "github:mightyiam/files";
      flake = false;
      inputs = {
        flake-parts.follows = "flake-parts";
        git-hooks.follows = "git-hooks-nix";
        import-tree.follows = "import-tree";
        nixpkgs.follows = "nixpkgs-unstable";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    flake-file.url = "github:denful/flake-file/main";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs-unstable";
    };
    gen-schema.url = "github:sini/gen-schema";
    git-hooks-nix.url = "github:cachix/git-hooks.nix";
    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    import-tree.url = "github:denful/import-tree";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    pkgs-by-name-for-flake-parts.url = "github:drupol/pkgs-by-name-for-flake-parts";
    preservation.url = "github:nix-community/preservation";
    shimmer = {
      url = "github:nuclearcodecat/shimmer/main";
      flake = false;
    };
    treefmt-nix.url = "github:numtide/treefmt-nix";
    wrappers = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };
}
