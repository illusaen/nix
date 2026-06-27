{
  inputs,
  config,
  ...
}: {
  flake.modules.nixos.boot = {
    imports = with config.flake.modules.nixos; [
      inputs.disko.nixosModules.disko
      disko
      boot-hardware
      facter
    ];
  };
}
