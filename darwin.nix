let
  api = import ./default.nix;
  hostLib = import ./lib/hosts.nix {
    inherit (api) featureLib fleetLib packageLib;
    lib = api.nixpkgsLib;
  };
in
  hostLib.mkDarwinConfigurations {
    inherit (api) fleet sources;
  }
