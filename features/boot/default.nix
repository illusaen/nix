{
  imports = [];

  modules.nixos = {
    host,
    lib,
    sources,
    ...
  }: let
    facterReport = ../../gen-modules/fleet/hosts/${host.name}/facter.json;
  in {
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

    hardware.facter = lib.mkIf (builtins.pathExists facterReport) {
      reportPath = facterReport;
      detected.dhcp.enable = false;
    };
  };
}
