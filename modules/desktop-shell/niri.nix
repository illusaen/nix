{
  flake.modules.nixos.niri = {pkgs, ...}: {
    programs.niri = {
      enable = true;
      package =
        pkgs.local.niri or pkgs.niri;
    };
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
  };
}
