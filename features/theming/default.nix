_: {
  imports = [];

  modules.nixos = {
    fleet,
    lib,
    ...
  }: let
    inherit (fleet.fonts) sans sizes;
    inherit (fleet.theming) cursor gtk icon;
    gtkSettings = {
      gtk-font-name = "${sans.name} ${toString sizes.applications}";
      gtk-theme-name = gtk.name;
      gtk-icon-theme-name = icon.name;
      gtk-cursor-theme-name = cursor.name;
      gtk-cursor-theme-size = cursor.size;
    };
    gtkIni = lib.generators.toINI {} {Settings = gtkSettings;};
  in {
    environment.sessionVariables = {
      GTK_THEME = gtk.name;
      XCURSOR_SIZE = toString cursor.size;
      XCURSOR_THEME = cursor.name;
    };

    environment.etc = {
      "xdg/gtk-3.0/settings.ini".text = gtkIni;
      "xdg/gtk-4.0/settings.ini".text = gtkIni;
    };

    programs.dconf = {
      enable = true;
      profiles.user.databases = [
        {
          settings = {
            "org/gnome/desktop/interface" = {
              font-name = "${sans.name} ${toString sizes.applications}";
              gtk-theme = gtk.name;
              icon-theme = icon.name;
              cursor-theme = cursor.name;
              cursor-size = lib.gvariant.mkUint32 cursor.size;
            };
            "org/gnome/desktop/wm/preferences"."button-layout" = "close:";
          };
        }
      ];
    };
  };

  modules.darwin = _: {};
}
