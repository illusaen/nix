{
  modules.nixos = {
    host,
    lib,
    serviceLib,
    options,
    config,
    ...
  }: let
    service = serviceLib.requireRoutedService host "linkding";
  in
    lib.mkMerge [
      {
        services.linkding = {
          enable = true;
          openFirewall = true;
          inherit (service) port;
        };
      }
      (lib.mkIf (options ? persist) {
        persist.directories = [
          {
            directory = config.services.linkding.dataDir;
            user = "linkding";
            group = "linkding";
            mode = "0700";
          }
        ];
      })
    ];
}
