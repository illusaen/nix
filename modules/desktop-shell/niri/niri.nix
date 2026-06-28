{config, ...}: {
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

    nix.settings = {
      extra-substituters = ["https://niri.cachix.org"];
      extra-trusted-public-keys = [
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      ];
    };
  };

  flake.wrappers.niri = {
    wlib,
    pkgs,
    ...
  }: let
    scheme = config.fleet.base16.scheme pkgs;
    animations = import ./_animations.nix;
    extra = import ./_extra.nix;
    mouse = import ./_mouse.nix {
      cursor = {
        name = "";
        size = 28;
      };
    };
    recent-windows = import ./_window-switcher.nix {highlightColor = scheme.withHashtag.base0D;};
    layout = import ./_layout.nix {scheme = scheme.withHashtag;};
    rules = import ./_rules.nix;
    binds = import ./_binds.nix;
    outputs = import ./_outputs.nix {monitors = config.fleet.monitors.conn;};
    workspaces = import ./_workspaces.nix {monitors = config.fleet.monitors.conn;};
  in {
    imports = [wlib.wrapperModules.niri];
    settings =
      {
        inherit layout binds outputs workspaces animations recent-windows;
        inherit (rules) layer-rules window-rules;
      }
      // rules // extra // mouse;
  };
}
