{
  flake.modules.nixos.networking = {lib, ...}: {
    # Configure network connections interactively with nmcli or nmtui.
    networking.networkmanager.enable = true;
    networking.hostId = lib.mkDefault "b9443213";

    persist.directories = [
      "/etc/NetworkManager/system-connections"
    ];
  };
}
