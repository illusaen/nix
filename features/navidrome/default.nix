let
  serviceSecrets = {hosts, ...}:
    map (hostName: {
      secret = "shared/navidrome-env.age";
      inherit hostName;
    })
    hosts;
in {
  inherit serviceSecrets;

  tests.serviceSecrets =
    serviceSecrets {
      hosts = ["odin" "huginn"];
    }
    == [
      {
        secret = "shared/navidrome-env.age";
        hostName = "odin";
      }
      {
        secret = "shared/navidrome-env.age";
        hostName = "huginn";
      }
    ];

  modules.nixos = {
    config,
    host,
    lib,
    options,
    ...
  }: let
    service = host.services.navidrome;
    enabled = service.role == "primary" || service.role == "backup";
    secretFile = ../../secrets/shared/navidrome-env.age;
  in {
    config = lib.mkIf enabled (lib.mkMerge [
      {
        assertions = [
          {
            assertion = service.protocol == "http" || service.protocol == "https";
            message = "navidrome expects an HTTP transport protocol";
          }
        ];

        services.navidrome =
          {
            enable = true;
            openFirewall = true;
            settings = {
              Address = "0.0.0.0";
              Port = service.port;
              DataFolder = "/var/lib/navidrome";
              MusicFolder = "/srv/music";
            };
          }
          // {
            environmentFile = lib.mkIf (builtins.pathExists secretFile) config.age.secrets.navidrome-env.path;
          };
      }
      (lib.mkIf (builtins.pathExists secretFile) {
        age.secrets.navidrome-env = {
          file = secretFile;
          owner = "navidrome";
          group = "navidrome";
        };
      })
      (lib.mkIf (options ? persist) {
        persist.directories = [
          {
            directory = "/var/lib/navidrome";
            user = "navidrome";
            group = "navidrome";
            mode = "0700";
          }
          {
            directory = "/srv/music";
            user = "navidrome";
            group = "navidrome";
            mode = "0750";
          }
        ];
      })
    ]);
  };
}
