{
  flake.moduleImports.nixos.hardware = [
    "audio"
    "bluetooth"
    "networking"
    "facter"
  ];

  flake.modules.nixos.hardware = {};
}
