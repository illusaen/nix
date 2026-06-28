{config, ...}: {
  flake.modules.nixos.hardware.imports = with config.flake.modules.nixos; [
    audio
    bluetooth
    networking
    facter
  ];
}
