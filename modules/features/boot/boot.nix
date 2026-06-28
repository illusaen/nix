{config, ...}: {
  flake.modules.nixos.boot = {
    imports = with config.flake.modules.nixos; [
      disko
      preservation
    ];

    boot = {
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;
      initrd.systemd.enable = true;
      initrd.availableKernelModules = ["usb_storage"];
    };
  };
}
