{
  flake.modules.nixos.boot = {
    boot = {
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;
      initrd.systemd.enable = true;
      initrd.availableKernelModules = ["usb_storage"];
    };
  };

  flake.moduleImports.nixos.boot = [
    "disko"
  ];
}
