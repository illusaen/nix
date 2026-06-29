{
  flake.modules.nixos.facter = {host, ...}: {
    hardware.facter = {
      reportPath = host.facter;
      detected.dhcp.enable = false;
    };
  };
}
