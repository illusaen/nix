{
  inputs,
  helpers,
  ...
}: {
  flake-file.inputs.shimmer = {
    url = "github:nuclearcodecat/shimmer/main";
    flake = false;
  };

  flake.modules.nixos.firefox = {
    pkgs,
    lib,
    config,
    user,
    ...
  }: let
    shimmer = inputs.shimmer.outPath;
    profileType = lib.types.submodule {
      options = {
        id = lib.mkOption {
          type = lib.types.int;
          readOnly = true;
          description = "id of firefox profile, computed from list of profiles";
        };
        name = lib.mkOption {
          type = lib.types.str;
          readOnly = true;
          description = "name of profile, computed from key";
        };
        path = lib.mkOption {
          type = lib.types.str;
          readOnly = true;
          description = "path relative to firefox config folder";
        };
        isDefault = lib.mkOption {
          type = lib.types.enum [0 1];
          default = 0;
          description = "if the profile is the default";
        };
        userChrome = lib.mkOption {
          type = lib.types.either lib.types.path lib.types.lines;
          description = "userChrome css file in text or path form";
        };
        userContent = lib.mkOption {
          type = lib.types.either lib.types.path lib.types.lines;
          description = "userContent css file in text or path form";
        };
      };
    };

    firefoxIni = let
      mkProfile = _name: profile: {
        "Profile${toString profile.id}" = {
          Name = profile.name;
          IsRelative = 1;
          Path = profile.path;
          Default = profile.isDefault;
        };
      };
      sections = lib.flatten [
        {
          General = {
            StartWithLastProfile = 1;
            Version = 2;
          };
        }
        (lib.mapAttrsToList mkProfile config.programs.firefox.profiles)
      ];
    in
      helpers.toGtkIni (lib.foldl' lib.recursiveUpdate {} sections);
  in {
    options.programs.firefox.profiles = lib.mkOption {
      type = lib.types.attrsOf profileType;
      apply = value: let
        indexed = builtins.attrNames value;
        indices = builtins.listToAttrs (lib.imap0 (i: name: lib.nameValuePair name i) indexed);
        cssSource = name: fileName: value:
          if lib.types.path.check value
          then toString value
          else toString (pkgs.writeText "${name}-${fileName}" value);
      in
        lib.mapAttrs (name: profile: (
          profile
          // {
            inherit name;
            id = indices.${name};
            userChrome = cssSource name "userChrome.css" profile.userChrome;
            userContent = cssSource name "userContent.css" profile.userContent;
            path = let
              suffix =
                if profile.isDefault == 1
                then ".default"
                else "";
            in "${name}${suffix}";
          }
        ))
        value;
    };
    config.programs.firefox.profiles.default = {
      isDefault = 1;
      userChrome = "${shimmer}/userChrome.css";
      userContent = "${shimmer}/userContent.css";
    };
    config.systemd.tmpfiles.settings.firefox = let
      dir = "/home/${user.name}/.config/mozilla/firefox";
      mkTmpfile = _name: profile: let
        profileDir = "${dir}/${profile.path}";
        chromeDir = "${profileDir}/chrome";
      in {
        "${profileDir}".d = {
          user = user.name;
          group = "users";
          mode = "0700";
        };
        "${chromeDir}".d = {
          user = user.name;
          group = "users";
          mode = "0700";
        };
        "${chromeDir}/userChrome.css"."C+" = {
          user = user.name;
          group = "users";
          mode = "0644";
          argument = profile.userChrome;
        };
        "${chromeDir}/userContent.css"."C+" = {
          user = user.name;
          group = "users";
          mode = "0644";
          argument = profile.userContent;
        };
      };
      entries = lib.flatten [
        {
          "${dir}/profiles.ini"."f+" = {
            user = user.name;
            group = "users";
            mode = "0644";
            argument = firefoxIni;
          };
        }
        (lib.mapAttrsToList mkTmpfile config.programs.firefox.profiles)
      ];
    in
      lib.mkMerge entries;
  };
}
