_: {
  fleet.hosts.odin = {
    system = "x86_64-linux";
    owner = "wendy";
    moduleNames = [
      "base"
      "boot"
      "nvidia"
      "desktop-shell"
      "programs"
      "hardware"
      "theming"
      "wendy"
    ];
  };

  debug = true;
  nixos.configurations.odin.extraModule = {pkgs, ...}: {
    networking = {
      hostName = "odin";
      hostId = "abf835ae";
      domain = "lan";
    };
    nixpkgs.hostPlatform = "x86_64-linux";
    environment.systemPackages = [pkgs.local.misc-scripts];
  };
}
