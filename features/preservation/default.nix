_: {
  imports = [];

  modules.nixos = {
    config,
    host,
    lib,
    pkgs,
    sources,
    user,
    ...
  }: let
    inherit (host.preservation) homeSnapshot persistMount rootSnapshot;
    inherit (lib) mkOption optionalAttrs;
    hasStaticInterfaces = (host.networkInterfaces or {}) != {};
    inherit (lib.types) attrsOf bool either listOf str submodule;
    withOptionsType = attrsOf (either bool str);
    mkPersistList = description:
      mkOption {
        type = listOf (either str withOptionsType);
        default = [];
        apply = lib.unique;
        inherit description;
      };
    mkPersistOption = withMountOptions: description:
      mkOption {
        type = submodule {
          options =
            {
              directories = mkPersistList "List of directories";
              files = mkPersistList "List of files";
            }
            // optionalAttrs withMountOptions {
              commonMountOptions = mkOption {
                type = listOf str;
                default = [];
              };
            };
        };
        inherit description;
      };
  in {
    imports = ["${sources.preservation.outPath}/module.nix"];

    options.persist = mkPersistOption false "Persistent root directories/files";
    options.persistUser = mkPersistOption true "Persistent user directories/files";
    options.ignored = mkPersistOption false "Ignored root directories/files used in find ephem";
    options.ignoredUser = mkPersistOption false "Ignored user directories/files used in find ephem";

    config = {
      persist = {
        directories =
          [
            "/var/log"
            "/var/lib/systemd/timers"
            "/var/lib/systemd/rfkill"
            "/var/lib/systemd/coredump"
            {
              directory = "/var/lib/nixos";
              inInitrd = true;
            }
          ]
          ++ lib.optionals (!hasStaticInterfaces) [
            "/etc/NetworkManager/system-connections"
          ];
        files = [
          {
            file = "/etc/machine-id";
            inInitrd = true;
          }
          {
            file = "/var/lib/systemd/random-seed";
            how = "symlink";
            inInitrd = true;
            configureParent = true;
          }
        ];
      };

      persistUser = {
        commonMountOptions = [
          "x-gvfs-hide"
          "x-gvfs-trash"
        ];
        directories = [
          {
            directory = ".local/share/keyrings";
            mode = "0700";
          }
          "Downloads"
          "Projects"
          "Pictures"
        ];
      };

      preservation = {
        enable = true;
        preserveAt.${persistMount} = config.persist // {users.${user.name or host.owner} = config.persistUser;};
      };

      boot.initrd.systemd.services.zfs-rollback = {
        description = "Rollback ZFS root dataset to blank snapshot";
        wantedBy = ["initrd.target"];
        after = ["zfs-import-zroot.service"];
        before = ["sysroot.mount"];
        path = [pkgs.zfs];
        unitConfig.DefaultDependencies = "no";
        serviceConfig.Type = "oneshot";
        script = ''
          zfs rollback -r ${rootSnapshot} && echo "zfs root rollback complete"
          zfs rollback -r ${homeSnapshot} && echo "zfs home rollback complete"
        '';
      };

      systemd.services.systemd-machine-id-commit = lib.mkDefault {
        unitConfig.ConditionPathIsMountPoint = [
          ""
          persistMount
        ];
        serviceConfig.ExecStart = [
          ""
          "${pkgs.systemd}/bin/systemd-machine-id-setup --commit --root ${persistMount}"
        ];
      };

      fileSystems."${persistMount}".neededForBoot = true;
      systemd.tmpfiles.settings.preservation."/home/${user.name or host.owner}".d = {
        user = user.name or host.owner;
        group = "users";
        mode = "0700";
      };
    };
  };
}
