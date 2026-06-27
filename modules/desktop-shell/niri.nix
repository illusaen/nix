{
  flake.modules.nixos.niri = {config, ...}: {
    programs.niri.enable = true;
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };

    services.xserver.videoDrivers = ["nvidia"];

    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      open = false;
      package = config.boot.kernelPackages.nvidiaPackages.latest;
    };
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
}
