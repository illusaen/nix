let
  api = import ./default.nix;
  hostLib = import ./lib/hosts.nix {
    inherit (api) featureLib fleetLib;
  };
in
  hostLib.mkDarwinConfigurations {
    inherit (api) fleet sources;
  }
