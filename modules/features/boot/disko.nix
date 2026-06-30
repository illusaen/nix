{inputs, ...}: {
  flake.modules.nixos.disko = {host, ...}: {
    imports = [inputs.disko.nixosModules.disko (import ./_disko.nix)];
    boot.zfs.forceImportRoot = true;
    disko.devices.disk.main.device = "/dev/${host.preservation.disk}";
  };
}
