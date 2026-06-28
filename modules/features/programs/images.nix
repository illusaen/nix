{
  flake.modules.nixos.images = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      image-roll
      inkscape
    ];
    xdg.mime.defaultApplications = {
      "image/*" = "com.github.weclaw1.ImageRoll.desktop";
    };
  };

  flake.modules.darwin.images.homebrew.masApps."Pixelmator Pro" = 1289583905;
}
