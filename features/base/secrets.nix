{inputs}: {
  modules = {
    generic = {host, ...}: {
      age.identityPaths = [host.privateKey];
    };

    nixos = [
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

    darwin = inputs.agenix.darwinModules.default;
  };
}
