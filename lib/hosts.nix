{
  fleetLib,
  featureLib,
  packageLib,
  serviceLib,
}: {
  mkHostModule = {
    fleet,
    host,
    sources,
  }: let
    user = fleet.users.${host.owner} // {name = host.owner;};
  in {
    imports = featureLib.modulesForHost host;

    config = {
      nixpkgs.overlays = [packageLib.overlay];

      _module.args = {
        inherit fleet fleetLib host serviceLib sources user;
      };
    };
  };
}
