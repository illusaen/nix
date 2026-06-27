{
  inputs,
  config,
  rootPath,
  ...
}: let
  genSchema = inputs.gen-schema.lib;
in {
  options.fleet.hosts = genSchema.mkInstanceRegistry config.schema.host {
    refs.owner = config.fleet.users;
    extraModules = [
      (
        {config, ...}: {
          secretPath = rootPath + "/secrets/hosts/${config.name}";
          facts = rootPath + "/hosts/${config.name}/facter.json";
          publicKey =
            if config.secretPath != null
            then config.secretPath + "/host_ed25519.pub"
            else null;
        }
      )
    ];
  };
  options.fleet.users = genSchema.mkInstanceRegistry config.schema.user {};
}
