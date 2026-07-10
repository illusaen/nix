_: {
  imports = [];

  modules.nixos = {
    fleet,
    host,
    lib,
    pkgs,
    ...
  }: let
    fontPackages = with pkgs; [
      font-awesome
      inter
      material-symbols
      monaspace
      noto-fonts-color-emoji
    ];
    desktopPackages = with pkgs;
      [
        ddcutil
        libheif
        nautilus
        pavucontrol
        playerctl
        xwayland-satellite
      ]
      ++ lib.optional (pkgs ? swaylock) pkgs.swaylock;
    sddmExtraPackages = with pkgs; [
      qt6.qt5compat
      weston
    ];
  in {
    environment.systemPackages = fontPackages ++ desktopPackages;
    environment.pathsToLink = ["share/thumbnailers"];

    fonts = {
      packages = fontPackages;
      fontconfig.defaultFonts = {
        monospace = [fleet.fonts.mono.name];
        sansSerif = [fleet.fonts.sans.name];
        emoji = [fleet.fonts.emoji.name];
      };
    };

    hardware = {
      bluetooth.settings.General.Experimental = true;
      i2c.enable = true;
    };

    programs = {
      dconf.enable = true;
      niri.enable = true;
      nautilus-open-any-terminal = {
        enable = true;
        terminal = "alacritty";
      };
    };

    services = {
      blueman.enable = true;
      gvfs.enable = true;
      libinput.enable = true;
      playerctld.enable = true;
      pulseaudio.enable = false;
      udisks2.enable = true;
      xserver.xkb.layout = "us";

      displayManager = {
        enable = true;
        defaultSession = "niri";
        sddm = {
          enable = true;
          enableHidpi = true;
          extraPackages = sddmExtraPackages;
          wayland = {
            enable = true;
            compositor = "weston";
            compositorCommand = let
              westonIni = (pkgs.formats.ini {}).generate "weston.ini" (
                lib.optionalAttrs ((host.monitors.secondary or null) != null) {
                  output = {
                    name = host.monitors.secondary;
                    mode = "off";
                  };
                }
              );
            in "${lib.getExe pkgs.weston} --shell=kiosk -c ${westonIni}";
          };
        };
      };

      gnome.sushi.enable = true;
      pipewire = {
        enable = true;
        alsa = {
          enable = true;
          support32Bit = true;
        };
        pulse.enable = true;
      };
    };

    security.rtkit.enable = true;

    persist.directories = [
      "/var/lib/bluetooth"
    ];

    nix.settings = {
      extra-substituters = ["https://niri.cachix.org"];
      extra-trusted-public-keys = [
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      ];
    };
  };

  modules.darwin = {fleet, ...}: {
    system.activationScripts.setDesktopBackground = ''
      echo "Setting desktop background."
      osascript -e 'tell application "System Events" to tell every desktop to set picture to "${fleet.wallpaper.image}"'
    '';
  };
}
