{
  flake.modules.nixos.networking = {host, ...}: {
    networking.networkmanager.enable = true;
    networking.hostId = host.hostId;

    persist.directories = [
      "/etc/NetworkManager/system-connections"
    ];
  };
}
