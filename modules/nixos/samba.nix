# Base NixOS module - core configurations enabled by default
{
  config,
  lib,
  vars,
  ...
}:
let
  inherit (vars) name seedbox;
  cfg = config.modules.samba;
in
{
  options.modules.samba = {
    enable = mkEnableOption "samba nixos configuration";
  };

  config = lib.mkIf cfg.enable {
    services.samba = {
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          "server string" = "smbnix";
          "netbios name" = "smbnix";
          "workgroup" = "WORKGROUP";
        };
      }
      // (
        seedbox.hd
        |> lib.mapAttrs' (
          _: value:
          let
            hdName = lib.toLower value;
          in
          lib.nameValuePair hdName {
            "path" = "/mnt/${hdName}";
            "browseable" = "yes";
            "valid users" = "${name}";
            "force user" = "${name}";
            "public" = "no";
            "writeable" = "yes";
            "fruit:aapl" = "yes";
            "fruit:model" = "MacSamba";
            "vfs objects" = "catia fruit streams_xattr";
          }
        )
      );
    };

    services.samba-wsdd = {
      enable = true;
      openFirewall = true;
      discovery = true;
    };

    services.avahi = {
      publish.enable = true;
      publish.userServices = true;
      # ^^ Needed to allow samba to automatically register mDNS records (without the need for an `extraServiceFile`
      nssmdns4 = true;
      # ^^ Not one hundred percent sure if this is needed- if it aint broke, don't fix it
      enable = true;
      openFirewall = true;
    };
  };
}
