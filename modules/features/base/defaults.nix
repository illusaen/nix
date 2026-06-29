{
  flake.modules.generic.defaults = {host, ...}: {
    nixpkgs.hostPlatform = host.system;
    networking.hostName = host.name;
  };

  flake.modules.nixos.defaults = {user, ...}: {
    users.users.${user.name} = {
      isNormalUser = true;
      extraGroups = ["wheel" "networkmanager"]; # Enable ‘sudo’ for the user.
      password = "arst";
    };
  };
}
