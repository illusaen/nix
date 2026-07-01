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
    configDir = "/home/${user.name}/.config/mozilla/firefox";

    cssFileType = lib.types.submodule {
      options = {
        name = lib.mkOption {type = lib.types.str;};
        file = lib.mkOption {type = lib.types.path;};
        type = lib.mkOption {type = lib.types.enum ["userChrome" "userContent"];};
      };
    };
    profileType = lib.types.submodule {
      options = {
        isDefault = lib.mkOption {
          type = lib.types.enum [0 1];
          default = 0;
          description = "if the profile is the default";
        };
        userChrome = lib.mkOption {
          type = lib.types.lines;
          default = "";
          description = "userChrome css";
        };
        userContent = lib.mkOption {
          type = lib.types.lines;
          default = "";
          description = "userContent css";
        };
        otherCss = lib.mkOption {
          type = lib.types.listOf cssFileType;
          default = [];
          description = "other css files from 3rd party repos. automatically imported at the top of userChrome/userContent.css";
        };
      };
    };

    rawProfiles = config.programs.firefox.profiles;
    profileIds =
      builtins.listToAttrs
      (lib.imap0 (i: name: lib.nameValuePair name i) (builtins.attrNames rawProfiles));

    cssImport = file: ''@import url("${file}");'';
    writeCss = name: fileName: content:
      toString (pkgs.writeText "${name}-${fileName}" content);

    normalizeProfile = name: profile: let
      otherCss = map (file: file // {file = toString file.file;}) profile.otherCss;
      importsFor = type:
        map (file: cssImport file.name) (builtins.filter (file: file.type == type) otherCss);
      withImports = type: content:
        lib.concatStringsSep "\n" (importsFor type ++ [content]);
    in
      profile
      // {
        inherit name otherCss;
        id = profileIds.${name};
        path = name + lib.optionalString (profile.isDefault == 1) ".default";
        userChrome = writeCss name "userChrome.css" (withImports "userChrome" profile.userChrome);
        userContent = writeCss name "userContent.css" (withImports "userContent" profile.userContent);
      };

    profiles = lib.mapAttrs normalizeProfile rawProfiles;

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
        (lib.mapAttrsToList mkProfile profiles)
      ];
    in
      helpers.toGtkIni (lib.foldl' lib.recursiveUpdate {} sections);
  in {
    options.programs.firefox.profiles = lib.mkOption {
      type = lib.types.attrsOf profileType;
    };
    config.programs.firefox.profiles.default = {
      isDefault = 1;
      userChrome = ''
        #TabsToolbar {
          display: none !important;
        }
      '';
      otherCss = [
        {
          file = "${shimmer}/userChrome.css";
          name = "shimmerChrome.css";
          type = "userChrome";
        }
        {
          file = "${shimmer}/userContent.css";
          name = "shimmerContent.css";
          type = "userContent";
        }
      ];
    };
    config.systemd.tmpfiles.settings.firefox = let
      mkTmpfile = _name: profile: let
        profileDir = "${configDir}/${profile.path}";
        chromeDir = "${profileDir}/chrome";
        mkDir = {
          user = user.name;
          group = "users";
          mode = "0700";
        };
        mkFile = target: {
          "L+".argument = target;
        };
      in
        {
          "${profileDir}".d = mkDir;
          "${chromeDir}".d = mkDir;
          "${chromeDir}/userChrome.css" = mkFile profile.userChrome;
          "${chromeDir}/userContent.css" = mkFile profile.userContent;
        }
        // (profile.otherCss
          |> map (f:
            lib.nameValuePair "${chromeDir}/${f.name}" (mkFile f.file))
          |> builtins.listToAttrs);
    in
      lib.mkMerge (lib.flatten [
        {
          "${configDir}/profiles.ini"."f+" = {
            user = user.name;
            group = "users";
            mode = "0644";
            argument = firefoxIni;
          };
        }
        (lib.mapAttrsToList mkTmpfile profiles)
      ]);
  };
}
