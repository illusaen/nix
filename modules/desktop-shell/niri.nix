{
  flake.modules.nixos.niri = {
    programs.niri.enable = true;
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
  };
}
