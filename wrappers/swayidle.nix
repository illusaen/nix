{
  wlib,
  lib,
  pkgs,
  ...
}: let
  display = status: "${lib.getExe pkgs.local.niri} msg action power-${status}-monitors";
in {
  imports = [
    wlib.wrapperModules.swayidle
    ./service.nix
  ];

  config.service = {
    enable = true;
    description = "swayidle for monitor power on and off";
  };
  config.events.after-resume = display "on";
  config.timeouts = [
    {
      timeout = 300; # in seconds
      command = "${pkgs.libnotify}/bin/notify-send 'Turning off monitors in 5 seconds' -t 5000";
    }
    {
      timeout = 305;
      command = display "off";
    }
  ];
}
