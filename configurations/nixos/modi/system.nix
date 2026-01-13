{
  lib,
  pkgs,
  vars,
  ...
}:
let
  inherit (vars) name fullName seedbox;
  inherit (seedbox)
    hostName
    ip
    gateway
    domain
    group
    hd
    ;
in
{
  nixpkgs.hostPlatform = "aarch64-linux";

  system.stateVersion = "25.11";

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };

    "/mnt/samba" = {
      device = "zsafe/samba";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };
  }
  // (lib.mapAttrs' (
    _: value:
    lib.nameValuePair "/mnt/${lib.toLower value}" {
      device = "/dev/disk/by-label/${value}";
      options = [
        "uid=1000"
        "gid=100"
      ];
    }
  ) hd);

  nixpkgs.overlays = [
    (_: super: {
      makeModulesClosure = x: super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  boot = {
    loader = {
      generic-extlinux-compatible.enable = true;
      grub.enable = lib.mkForce false;
    };
  };

  services = {
    getty.autologinUser = lib.mkOverride 999 name;
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "yes";
        PasswordAuthentication = false;
      };
    };
  };

  networking =
    let
      interface = "end0";
    in
    {
      nftables.enable = true;
      hosts = {
        "${ip}" = [
          domain
          hostName
        ];
      };
      interfaces."${interface}".ipv4.addresses = [
        {
          address = "${ip}";
          prefixLength = 24;
        }
      ];
      defaultGateway = {
        address = gateway;
        inherit interface;
      };
      enableIPv6 = false;
    };

  system.nssModules = lib.optional true pkgs.nssmdns;
  system.nssDatabases.hosts = lib.optionals true (
    lib.mkMerge [
      (lib.mkBefore [ "mdns4_minimal [NOTFOUND=return]" ]) # before resolve
      (lib.mkAfter [ "mdns4" ]) # after dns
    ]
  );

  users.users.${name} = {
    isNormalUser = true;
    description = fullName;
    shell = pkgs.fish;
    home = "/home/${name}";
  };
  systemd.tmpfiles.rules = [ "d /mnt/samba 0755 ${name} ${group}" ];
}
