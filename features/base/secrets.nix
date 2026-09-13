{inputs}: {
  modules.generic = {host, ...}: {
    age.identityPaths = [host.privateKey];
  };

  modules.nixos = [
    inputs.agenix.nixosModules.default
    (
      {
        host,
        lib,
        options,
        ...
      }:
        lib.mkIf (options ? persist) {
          persist.files = [
            {
              file = host.privateKey;
              mode = "0640";
              group = "wheel";
            }
          ];
        }
    )
  ];

  modules.darwin = inputs.agenix.darwinModules.default;
}
