{
  flake.moduleImports.nixos.hardware = [
    "audio"
    "bluetooth"
    "networking"
    "facter"
  ];
}
