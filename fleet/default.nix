{
  domain = "home.arpa";
  timeZone = "America/Chicago";

  hosts = import ./hosts.nix;
  users = import ./users.nix;
  groups = import ./groups.nix;
  services = import ./services.nix;

  fonts = {
    sans = {
      name = "Inter";
      packageName = "inter";
    };
    mono = {
      name = "Monaspace Neon NF";
      packageName = "monaspace";
    };
    emoji = {
      name = "Noto Color Emoji";
      packageName = "noto-fonts-color-emoji";
    };
    icon = {
      name = "Material Symbols Outlined";
      packageName = "material-symbols";
    };
    sizes = {
      terminal = 12;
      applications = 12;
      desktop = 13;
    };
  };

  theming = {
    icon = {
      name = "MacTahoe";
      packageName = "mactahoe-icon-theme";
    };
    cursor = {
      name = "MacTahoe-Cursors";
      packageName = "mactahoe-cursors";
      size = 32;
    };
    gtk = {
      name = "MacTahoe";
      packageName = "mactahoe-gtk-theme";
    };
  };

  wallpaper = {
    directory = ../resources/wallpapers;
    image = ../resources/wallpapers/dark/dark-silk.jpeg;
  };
}
