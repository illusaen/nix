{
  helpers,
  lib,
  ...
}: {
  flake.modules.nixos.gtk = {
    fleet,
    pkgs,
    ...
  }: let
    inherit (fleet.theming) gtk icon cursor;
    inherit (fleet.fonts) sans sizes;
    inherit (fleet.base16) isDark;

    gtkIni =
      {
        gtk-font-name = "${sans.name} ${toString sizes.applications}";
        gtk-theme-name = gtk.name;
        gtk-icon-theme-name = icon.name;
        gtk-cursor-theme-name = cursor.name;
        gtk-cursor-theme-size = cursor.size;
        gtk-application-prefer-dark-theme =
          if isDark
          then true
          else null;
      }
      |> lib.filterAttrs (_: v: v != null)
      |> (attr: {Settings = attr;})
      |> helpers.toGtkIni;

    dconfSettings =
      {
        font-name = "${sans.name} ${toString sizes.applications}";
        gtk-theme = gtk.name;
        icon-theme = icon.name;
        cursor-theme = cursor.name;
        cursor-size = lib.gvariant.mkUint32 cursor.size;
        color-scheme =
          if isDark
          then "prefer-dark"
          else null;
      }
      |> lib.filterAttrs (_: v: v != null);
  in {
    environment.systemPackages = [pkgs.local.${gtk.packageName}];
    environment.sessionVariables = {
      GTK_THEME = gtk.name;
      XDG_DATA_DIRS = lib.mkBefore ["/run/current-system/sw/share"];
    };
    environment.etc = {
      "xdg/gtk-3.0/settings.ini".text = gtkIni;
      "xdg/gtk-4.0/settings.ini".text = gtkIni;
    };
    programs.dconf = {
      enable = true;
      profiles.user.databases = [
        {
          settings."org/gnome/desktop/wm/preferences" = {"button-layout" = "close:";};
          settings."org/gnome/desktop/interface" = dconfSettings;
        }
      ];
    };
  };
}
