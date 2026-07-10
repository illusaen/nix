_: {
  imports = [];

  modules.nixos = {
    config,
    lib,
    ...
  }: {
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "nvidia-kernel-modules"
        "nvidia-settings"
        "nvidia-x11"
      ];

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
