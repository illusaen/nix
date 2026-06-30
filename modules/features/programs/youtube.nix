{
  flake.wrappers.ytdlp = {
    wlib,
    pkgs,
    ...
  }: {
    imports = [wlib.modules.default];
    package = pkgs.yt-dlp;
    flags = {
      "-t" = "aac";
      "--cookies-from-browser" = "chrome";
    };
  };

  flake.modules.nixos.ytmdesktop = {pkgs, ...}: {
    environment.systemPackages = [pkgs.ytmdesktop pkgs.local.ytdlp];
  };
}
