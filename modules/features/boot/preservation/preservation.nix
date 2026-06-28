{inputs, ...}: {
  flake-file.inputs.preservation.url = "github:nix-community/preservation";

  flake.modules.nixos.preservation = {
    config,
    lib,
    pkgs,
    ...
  }: let
    persistMount = "/persist";
    userName = "wendy";
    rollbackSnapshotRoot = "zroot/local/root@blank";
    rollbackSnapshotHome = "zroot/local/home@blank";
  in {
    imports = [inputs.preservation.nixosModules.preservation];

    preservation = {
      enable = true;
      preserveAt.${persistMount} = config.persist // {users.${userName} = config.persistUser;};
    };

    boot.initrd.systemd.services.zfs-rollback = {
      description = "Rollback ZFS root dataset to blank snapshot";
      wantedBy = [
        "initrd.target"
      ];
      after = [
        # this is a dynamically generated service, based on the zpool name
        "zfs-import-zroot.service"
      ];
      before = [
        "sysroot.mount"
      ];
      path = with pkgs; [
        zfs
      ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = ''
        zfs rollback -r ${rollbackSnapshotRoot} && echo "zfs root rollback complete"
        zfs rollback -r ${rollbackSnapshotHome} && echo "zfs home rollback complete"
      '';
    };

    systemd.services.systemd-machine-id-commit = lib.mkDefault {
      # Ensure service will only run if the persistent storage is mounted
      unitConfig.ConditionPathIsMountPoint = [
        ""
        persistMount
      ];
      # Ensure service commits the ID to the persistent volume
      serviceConfig.ExecStart = [
        ""
        "${pkgs.systemd}/bin/systemd-machine-id-setup --commit --root ${persistMount}"
      ];
    };

    fileSystems."${persistMount}".neededForBoot = true;
  };
}