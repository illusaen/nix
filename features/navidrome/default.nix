{...}: {
  imports = [];

  modules.nixos = {
    host,
    lib,
    ...
  }: let
    service = host.services.navidrome;
  in {
    config = lib.mkIf (service.role == "primary") {
      services.navidrome = {
        enable = false;
        settings.Port = service.port;
      };
    };
  };
}
