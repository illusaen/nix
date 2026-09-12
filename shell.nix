{system ? builtins.currentSystem}:
(import ./lib/mk-dev-shell.nix {
  sources = import ./npins;
  inherit system;
}).shell
