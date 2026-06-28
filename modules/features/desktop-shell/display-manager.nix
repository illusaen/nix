{config, ...}: {
  flake.modules.nixos.display-manager = {
    pkgs,
    lib,
    ...
  }: let
    inherit (config.fleet.monitors) desc;
  in {
    programs.regreet = let
      inherit (config.fleet.theming) gtk icon cursor;
      inherit (config.fleet.fonts) sans sizes;
      inherit (config.fleet.wallpaper) image;
      timezone = config.fleet.timeZone;
      scheme = (config.fleet.base16.scheme pkgs).withHashtag;
    in {
      enable = true;
      theme = {
        package =
          pkgs.local.${gtk.packageName};
        inherit (gtk) name;
      };
      iconTheme = {
        package = pkgs.local.${icon.packageName};
        inherit (icon) name;
      };
      cursorTheme = {
        package = pkgs.local.${cursor.packageName};
        inherit (cursor) name;
      };
      font = {
        inherit (sans) name;
        package = pkgs.${sans.packageName};
        size = sizes.applications;
      };
      settings = {
        skip_selection = true;
        background = {
          path = image;
          fit = "Fill";
        };
        GTK = {
          application_prefer_dark_theme = true;
        };
        "widget.clock" = {
          format = "%A %B %d%n%I:%M %p";
          inherit timezone;
        };
      };
      extraCss = let
        inherit (scheme) base05;
      in ''
        * {
          color: ${base05};
          font-weight: 500;
          background-color: transparent;
          border: none;
          box-shadow: none;
          border-radius: 8px;
        }
        grid > label:nth-child(1), label:nth-child(2), grid > label:nth-child(4), combobox box > arrow {
          opacity: 0;
          min-width: 0;
          min-height: 0;
          padding: 0;
          margin: 0;
        }
        picture {
          filter: blur(32px);
          opacity: 0.8;
        }
        window {
          background-color: alpha(${base05}, 0.1);
        }
        combobox, entry {
          border: 1px solid alpha(${base05}, 0.5);
        }
        entry > text {
          padding: 2px 8px;
        }
        combobox cellview {
          padding: 0 4px;
        }
        combobox:focus, entry:focus {
          border: 1px solid ${base05};
        }
        button {
          padding: 8px 12px;
        }
        button:hover, infobar {
          background-color: alpha(${base05}, 0.25);
        }
      '';
    };
    security.pam.services = {
      greetd.enableGnomeKeyring = true;
      login.enableGnomeKeyring = true;
      swaylock.text = "auth include login";
    };
    services.displayManager.enable = true;
    services.greetd = let
      niri = pkgs.local.niri or pkgs.niri;
      regreet-session = pkgs.writeShellScript "regreet-niri-session" ''
        ${lib.getExe niri} msg action focus-monitor ${lib.escapeShellArg desc.main} || true
        ${lib.getExe pkgs.regreet}
        status=$?
        ${lib.getExe niri} msg action quit --skip-confirmation || true
        exit "$status"
      '';
      niri-config = pkgs.writeText "niri-config-regreet" ''
        // Mitigate potential GTK portal slowdowns during login
        environment {
          GTK_USE_PORTAL "0"
          GDK_DEBUG "no-portals"
        }
        spawn-at-startup "${regreet-session}"
      '';
    in {
      enable = true;
      settings = {
        default_session = {
          # Launch Niri using the minimal config for the login screen
          command = "${pkgs.dbus}/bin/dbus-run-session ${lib.getExe niri} -c ${niri-config}";
          user = "greeter";
        };
      };
    };
  };
}
