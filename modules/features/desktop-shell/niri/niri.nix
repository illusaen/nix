{
  flake.modules.nixos.niri = {pkgs, ...}: {
    programs.niri = {
      enable = true;
      package = pkgs.local.niri or pkgs.niri;
      useNautilus = true;
    };

    nix.settings = {
      extra-substituters = ["https://niri.cachix.org"];
      extra-trusted-public-keys = [
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      ];
    };

    environment.systemPackages = [pkgs.local.niri-scripts pkgs.xwayland-satellite];
  };

  flake.fleetWrappers.niri = {
    wlib,
    pkgs,
    fleet,
    ...
  }: let
    scheme = (fleet.base16.scheme pkgs).withHashtag;
    inherit (fleet.theming) cursor;
    monitors = fleet.monitors.conn;
    animations = import ./_animations.nix;
    extra = import ./_extra.nix;
    mouse = import ./_mouse.nix {
      cursor = removeAttrs cursor ["packageName"];
    };
    recent-windows = import ./_window-switcher.nix {highlightColor = scheme.base0D;};
    layout = import ./_layout.nix {inherit scheme;};
    rules = import ./_rules.nix;
    binds = import ./_binds.nix;
    outputs = import ./_outputs.nix {inherit monitors;};
    workspaces = import ./_workspaces.nix {inherit monitors;};
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
