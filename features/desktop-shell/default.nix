{
  imports = [./noctalia.nix ./niri ./nautilus.nix ./audio.nix ./fonts.nix ./sddm.nix ./autostart.nix];

  modules.nixos = {
    config,
    lib,
    options,
    pkgs,
    ...
  }: {
    environment.systemPackages = with pkgs; [
      ddcutil
      local.misc-scripts
    ];

    persist.directories = [
      "/var/lib/bluetooth"
    ];
    hardware = {
      bluetooth.settings.General.Experimental = true;
      i2c.enable = true;
    };
    services.blueman.enable = true;

    programs.dconf.enable = true;

    systemdAutostart = lib.mkIf (options ? systemdAutostart) [
      (let
        inherit (config.services.tailscale) package;
      in {
        inherit package;
        name = "tailscale-systray";
        exec = "${lib.getExe package} systray";
      })
    ];
  };

  modules.darwin = {fleet, ...}: {
    system.activationScripts.setDesktopBackground = ''
      echo "Setting desktop background."
      osascript -e 'tell application "System Events" to tell every desktop to set picture to "${fleet.wallpaper.image}"'
    '';
  };
}
