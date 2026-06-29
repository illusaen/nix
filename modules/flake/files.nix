{inputs, ...}: {
  flake-file.inputs.files = {
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
  imports = ["${inputs.files}/flake-module.nix"];

  perSystem.files.writer.app = true;
}
