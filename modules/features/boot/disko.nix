{inputs, ...}: {
  flake.modules.nixos.disko = {
    imports = [inputs.disko.nixosModules.disko (import ./_disko.nix)];
    boot.zfs.forceImportRoot = true;
    disko.devices.disk.main.device = "/dev/nvme0n1";
  };
}
