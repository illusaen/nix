{system ? builtins.currentSystem}: let
  sources = import ./npins;
  pkgs = import sources.nixpkgs.outPath {inherit system;};
in
  pkgs.mkShell {
    packages = with pkgs; [
      agenix
      colmena
      deadnix
      nil
      npins
      shellcheck
      statix
      treefmt
    ];
  }
