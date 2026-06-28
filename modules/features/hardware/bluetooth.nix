{
  flake.modules.nixos.bluetooth = {
    hardware.bluetooth.settings.General.Experimental = true;
    services.blueman.enable = true;
    persist.directories = [
      "/var/lib/bluetooth"
    ];
  };
}
