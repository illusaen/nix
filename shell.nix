{system ? builtins.currentSystem}: let
  sources = import ./npins;
  pkgs = import sources.nixpkgs.outPath {inherit system;};
  agenixPackage = pkgs.callPackage "${sources.agenix.outPath}/pkgs/agenix.nix" {};
in
  pkgs.mkShell {
    packages =
      [
        agenixPackage
      ]
      ++ (with pkgs; [
        alejandra
        colmena
        deadnix
        dix
        nil
        npins
        ruff
        shellcheck
        statix
        treefmt
      ]);
  }
