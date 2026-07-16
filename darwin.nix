let
  api = import ./default.nix;
in
  api.evalLib.mkDarwinConfigurations {
    inherit (api) fleet;
  }
