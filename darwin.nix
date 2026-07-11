let
  api = import ./default.nix;
  hostLib = import ./lib/hosts.nix {
    inherit (api) featureLib fleetLib packageLib;
  };
in
  hostLib.mkDarwinConfigurations {
    inherit (api) fleet sources;
  }
