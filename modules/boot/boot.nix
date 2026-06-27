{
  config,
  inputs,
  ...
}: {
  flake.modules.nixos.boot = {
    imports = [
      inputs.disko.nixosModules.disko
      config.flake.modules.nixos.disko
      config.flake.modules.nixos.boot-hardware
    ];
  };
}
