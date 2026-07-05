{
  config,
  inputs,
  lib,
  ...
}: {
  flake-file.inputs.gen-flake.url = "github:sini/gen-flake";
  imports = [inputs.gen-flake.flakeModules.default];
  gen.tree = ../../gen-modules;
  gen.specialArgs = {
    inherit inputs lib;
    rootPath = ../..;
    helpers = (import ./helpers-lib.nix {inherit lib;})._module.args.helpers;
  };

  flake.fleet = config.gen.composed.values.fleet;

  perSystem.files.file."docs/gen/schema.md".text =
    inputs.gen-flake.inputs.gen-schema.lib.renderDocs config.gen.composed.values.schema;
}
