{inputs, ...}: {
  flake.modules.nixos.disko =
    {
      imports = [inputs.disko.nixosModules.disko];
      boot.zfs.forceImportRoot = true;
      disko.devices.disk.main.device = "/dev/${"nvme0n1"}";
    }
    // (import ./_disko.nix);
}
