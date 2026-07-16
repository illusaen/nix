{
  modules.nixos = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      inkscape
      bambu-studio
      image-roll
      onlyoffice-desktopeditors
    ];

    xdg.mime.defaultApplications."image/*" = "com.github.weclaw1.ImageRoll.desktop";
  };

  modules.darwin = {
    homebrew = {
      casks = ["bambu-studio"];
      masApps."Pixelmator Pro" = 1289583905;
    };
  };
}
