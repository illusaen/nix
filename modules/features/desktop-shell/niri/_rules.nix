{
  layer-rules = [
    {
      matches = [{namespace = "^wpaperd.*$";}];
      place-within-backdrop = true;
    }
    {
      matches = [{namespace = "swaync-control-center";}];
      background-effect = {
        blur = true;
        xray = false;
      };
    }
  ];

  window-rules = [
    {
      geometry-corner-radius = 12;
      clip-to-geometry = true;
      tiled-state = true;
      popups = {
        opacity = 0.92;
        background-effect.blur = true;
      };
    }
    {
      matches = [{is-active = false;}];
      opacity = 0.9;
      background-effect.blur = true;
    }
    {
      matches = [{is-floating = true;}];
      background-effect = {
        blur = true;
        xray = false;
      };
      opacity = 0.96;
    }
    {
      matches = [{app-id = "^ndrop-alacritty$";}];
      open-floating = true;
      opacity = 0.8;
      background-effect.blur = true;
      default-floating-position = _: {
        props = {
          relative-to = "top";
          x = 0;
          y = 0;
        };
      };
      default-column-width.proportion = 0.4;
      default-window-height.proportion = 0.5;
    }
    {
      matches = [
        {title = "^(.*)(o|O|s|S)(pen|ave) (f|F|a|a)(ile|s)(.*)";}
        {app-id = "org.pulseaudio.pavucontrol";}
        {app-id = "^(.*)blueman-manager(.*)$";}
        {app-id = "xdg-desktop-portal-gtk";}
        {app-id = "xdg-desktop-portal-gnome";}
        {app-id = "nemo";}
        {app-id = "org.gnome.Nautilus";}
      ];
      open-floating = true;
      max-width = 1800;
      max-height = 1000;
    }
    {
      matches = [
        {app-id = "alacritty";}
      ];
      default-column-display = "tabbed";
    }
    {
      matches = [
        {app-id = "mpv";}
        {app-id = "youtube-music-desktop-app";}
      ];
      open-on-workspace = "music";
      default-column-width.proportion = 1.0;
    }
    {
      matches = [
        {app-id = "code";}
        {app-id = "dev.zed.Zed";}
        {app-id = "google-chrome";}
        {app-id = "firefox";}
      ];
      open-on-workspace = "code";
    }
    {
      matches = [{at-startup = true;}];
      open-focused = false;
    }
    {
      matches = [
        {
          at-startup = true;
          app-id = "1password";
        }
      ];
      open-on-workspace = "code";
    }
    {
      matches = [
        {
          app-id = "firefox";
          title = "Picture-in-Picture";
        }
      ];
      open-floating = true;
    }
    {
      matches = [
        {app-id = "vesktop";}
        {app-id = "discord";}
        {app-id = "Element";}
        {app-id = "org.telegram.desktop";}
      ];
      open-on-workspace = "chat";
    }
    {
      matches = [
        {title = "Viking Rise Steam";}
        {app-id = "steam.*";}
      ];
      open-on-workspace = "gaming";
    }
    {
      matches = [
        {title = "Viking Rise Steam";}
      ];
      min-width = 4192;
    }
    {
      matches = [
        {
          app-id = "steam";
          title = "^notificationtoasts_\\d+_desktop$";
        }
      ];
      open-focused = false;
      default-floating-position = _: {
        props = {
          relative-to = "bottom-right";
          x = 2;
          y = 2;
        };
      };
    }
  ];
}
