{inputs, ...}: {
  imports = [inputs.flake-file.flakeModules.dendritic];

  flake-file = {
    prune-lock.enable = true;
    nixConfig = {
      lazy-trees = true;
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operator"
      ];
    };

    inputs = {
      flake-file.url = "github:denful/flake-file/main";
      import-tree.url = "github:denful/import-tree";
      disko = {
        url = "github:nix-community/disko/latest";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      darwin = {
        url = "github:nix-darwin/nix-darwin/master";
        inputs.nixpkgs.follows = "nixpkgs-unstable";
      };
    };

    outputs = ''
      inputs: let
        evaluation = inputs.flake-parts.lib.evalFlakeModule {inherit inputs;} {
          imports = [((import inputs.import-tree) ./modules)];
          _module.args.rootPath = ./.;
        };
      in
        {inherit evaluation;} // evaluation.config.processedFlake
    '';
  };
}
