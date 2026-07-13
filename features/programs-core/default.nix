_: {
  imports = [];

  modules.nixos = {
    config,
    lib,
    pkgs,
    user,
    ...
  }: let
    userName = user.name or "wendy";
    optionalPackage = name:
      lib.optional (pkgs ? ${name}) pkgs.${name};
    wrappedYtDlp =
      if pkgs ? yt-dlp
      then
        pkgs.writeShellApplication {
          name = "yt-dlp";
          text = ''
            exec ${pkgs.yt-dlp}/bin/yt-dlp -t aac --cookies-from-browser firefox "$@"
          '';
        }
      else null;
    autostartEntryType = lib.types.submodule ({config, ...}: {
      options = {
        package = lib.mkOption {type = lib.types.package;};
        name = lib.mkOption {
          type = lib.types.str;
          default = lib.getName config.package;
        };
        exec = lib.mkOption {
          type = lib.types.str;
          default = lib.getExe config.package;
        };
      };
    });
    mkAutostartService = entry: {
      wantedBy = ["graphical-session.target"];
      partOf = ["graphical-session.target"];
      after = ["graphical-session.target"];
      description = "Autostarts ${entry.name} on login";
      serviceConfig = {
        ExecStart = entry.exec;
        Restart = "on-failure";
      };
    };
  in {
    options.systemdAutostart = lib.mkOption {
      type = lib.types.listOf autostartEntryType;
      default = [];
    };

    config = {
      environment.systemPackages =
        lib.optional (wrappedYtDlp != null) wrappedYtDlp
        ++ optionalPackage "ytmdesktop";

      programs = {
        firefox.enable = true;
        _1password.enable = pkgs ? _1password-cli;
        _1password-gui = lib.mkIf (pkgs ? _1password-gui) {
          enable = true;
          package = pkgs._1password-gui;
          polkitPolicyOwners = [userName];
        };
      };

      xdg.mime.defaultApplications = let
        browser = "firefox.desktop";
      in {
        "text/html" = browser;
        "x-scheme-handler/http" = browser;
        "x-scheme-handler/https" = browser;
        "x-scheme-handler/about" = browser;
      };

      persistUser.directories = [
        ".config/1Password"
        ".config/mozilla/firefox"
        ".config/YouTube Music Desktop App"
      ];

      systemdAutostart =
        lib.optional (pkgs ? _1password-gui) {
          name = "one-password";
          package = pkgs._1password-gui;
        }
        ++ lib.optional (pkgs ? ytmdesktop) {
          package = pkgs.ytmdesktop;
        };

      systemd.user.services =
        builtins.listToAttrs (map (entry: lib.nameValuePair entry.name (mkAutostartService entry)) config.systemdAutostart);
    };
  };

  modules.darwin = _: {
    homebrew.casks = ["firefox"];
  };
}
