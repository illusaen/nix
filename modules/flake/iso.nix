{
  flake.modules.nixos.iso = {
    modulesPath,
    host,
    config,
    lib,
    ...
  }: {
    imports = ["${toString modulesPath}/installer/cd-dvd/installation-cd-base.nix"];
    boot.supportedFilesystems.zfs = true;
    lib.isoFileSystems."/home" = {
      device = "zroot/local/home";
      fsType = "zfs";
      options = ["zfsutil"];
    };

    users.users.${host.owner.name}.uid = 1000;
    users.users.nixos.uid = 1001;

    isoImage.edition = lib.mkDefault config.networking.hostName;
    isoImage.makeEfiBootable = true;
    isoImage.makeUsbBootable = true;
    isoImage.squashfsCompression = "gzip -Xcompression-level 1";

    networking.networkmanager.enable = lib.mkImageMediaOverride true;
    networking.useDHCP = lib.mkImageMediaOverride true;
    networking.useNetworkd = lib.mkImageMediaOverride false;
    networking.wireless.enable = lib.mkImageMediaOverride false;
    security.sudo.enable = lib.mkImageMediaOverride true;
    security.sudo-rs.enable = lib.mkImageMediaOverride false;
    systemd.network.enable = lib.mkImageMediaOverride false;
  };
}
