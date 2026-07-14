{
  imports = [./hardware.nix];

  modules.nixos = {
    host,
    sources,
    ...
  }: {
    imports = [
      "${sources.disko.outPath}/module.nix"
      ./disko.nix
    ];

    disko.devices.disk.main.device = "/dev/${host.preservation.disk}";

    boot = {
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;
      initrd.systemd.enable = true;
      initrd.availableKernelModules = ["usb_storage"];
      zfs.forceImportRoot = true;
    };
  };
}
