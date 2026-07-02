{inputs, ...}: {
  flake.modules.nixos.boot = {host, ...}: {
    boot = {
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;
      initrd.systemd.enable = true;
      initrd.availableKernelModules = ["usb_storage"];
    };

    hardware.facter = {
      reportPath = host.facter;
      detected.dhcp.enable = false;
    };

    imports = [inputs.disko.nixosModules.disko (import ./_disko.nix)];
    boot.zfs.forceImportRoot = true;
    disko.devices.disk.main.device = "/dev/${host.preservation.disk}";
  };
}
