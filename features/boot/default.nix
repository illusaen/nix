_: {
  imports = [];

  modules.nixos = {
    host,
    sources,
    ...
  }: {
    imports = [
      "${sources.disko.outPath}/module.nix"
      ./disko.nix
    ];

    boot = {
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;
      initrd.systemd.enable = true;
      initrd.availableKernelModules = ["usb_storage"];
      zfs.forceImportRoot = true;
    };

    disko.devices.disk.main.device = "/dev/${host.preservation.disk}";
  };
}
