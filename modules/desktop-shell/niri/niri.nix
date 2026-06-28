{
  flake.modules.nixos.niri = {pkgs, ...}: {
    programs.niri = {
      enable = true;
      package = pkgs.local.niri or pkgs.niri;
      useNautilus = true;
    };

    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };

    # xdg.portal.extraPortals = with pkgs; [xdg-desktop-portal-gtk];

    nix.settings = {
      extra-substituters = ["https://niri.cachix.org"];
      extra-trusted-public-keys = [
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      ];
    };
  };

  flake.wrappers.niri = {wlib, ...}: {
    imports = [wlib.wrapperModules.niri];
  };
}
