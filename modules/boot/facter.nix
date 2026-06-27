{
  flake.modules.nixos.facter = {
    hardware.facter = {
      reportPath = ./facter.json;
      detected.dhcp.enable = false;
    };
  };
}
