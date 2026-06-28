{
  inputs,
  config,
  ...
}: {
  flake.modules.nixos.boot = {
    imports = with config.flake.modules.nixos; [
      inputs.disko.nixosModules.disko
      disko
    ];

    boot = {
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;
      initrd.systemd.enable = true;
    };
  };
}
