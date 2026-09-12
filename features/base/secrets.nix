{inputs}: {
  modules.generic = {host, ...}: {
    imports = [
      inputs.agenix.nixosModules.default
    ];

    age.identityPaths = [host.privateKey];
  };

  modules.nixos = {
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
    };
}
