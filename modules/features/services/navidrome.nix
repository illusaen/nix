{
  flake.modules.nixos.navidrome = {host, ...}: {
    services.navidrome = {
      enable = false;
      settings.Port = host.services.all.navidrome.port;
    };
  };
}
