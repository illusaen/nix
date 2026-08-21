{
  modules.nixos = {pkgs, ...}: let
    wrappedYtDlp = pkgs.writeShellApplication {
      name = "yt-dlp";
      text = ''
        exec ${pkgs.yt-dlp}/bin/yt-dlp -t aac --cookies-from-browser firefox "$@"
      '';
    };
  in {
    environment.systemPackages = [pkgs.ytmdesktop wrappedYtDlp];

    persistUser.directories = [
      ".config/YouTube Music Desktop App"
    ];

    systemdAutostart = [
      {
        package = pkgs.ytmdesktop;
      }
    ];
  };
}
