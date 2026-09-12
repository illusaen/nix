{
  modules.nixos = {pkgs, ...}: let
    wrappedYtDlp = pkgs.writeShellApplication {
      name = "yt-dlp";
      text = ''
        exec ${pkgs.yt-dlp}/bin/yt-dlp -t aac --cookies-from-browser chrome "$@"
      '';
    };
  in {
    environment.systemPackages = [pkgs.pear-desktop wrappedYtDlp];

    persistUser.directories = [
      ".config/YouTube Music"
    ];

    systemdAutostart = [
      {
        package = pkgs.pear-desktop;
      }
    ];
  };
}
