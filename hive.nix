import ./lib/mk-hive.nix {
  api = import ./default.nix;
  system = builtins.currentSystem;
}
