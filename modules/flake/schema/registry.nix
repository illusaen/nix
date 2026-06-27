{
  inputs,
  config,
  ...
}: let
  inherit (config) schema;
  genSchema = inputs.gen-schema.lib;
in {
  options.fleet.hosts = genSchema.mkInstanceRegistry schema.host {};
  options.fleet.users = genSchema.mkInstanceRegistry schema.user {};
}
