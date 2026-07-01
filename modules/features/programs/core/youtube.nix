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
      "--cookies-from-browser" = "firefox";
    };
  };

  flake.modules.nixos.ytmdesktop = {pkgs, ...}: {
    environment.systemPackages = [pkgs.ytmdesktop pkgs.local.ytdlp];
    persistUser.directories = [".config/YouTube Music Desktop App"];
    systemdAutostart = [{package = pkgs.ytmdesktop;}];
  };
}
