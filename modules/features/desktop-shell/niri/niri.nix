{
  flake.modules.nixos.niri = {
    fleet,
    moduleSettings,
    pkgs,
    ...
  }: let
    package = (pkgs.local.niri or pkgs.niri).passthru.wrap {
      _module.args = {
        inherit fleet moduleSettings;
      };
    };
  in {
    programs.niri = {
      enable = true;
      inherit package;
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

  flake.wrappers.niri = {
    config,
    lib,
    pkgs,
    wlib,
    ...
  }: let
    fleet = config._module.args.fleet or null;
    moduleSettings = config._module.args.moduleSettings or null;
    hasHostSettings = fleet != null && moduleSettings != null && moduleSettings ? monitors;
  in {
    imports = [wlib.wrapperModules.niri];

    settings = lib.mkIf hasHostSettings (
      let
        scheme = (fleet.base16.scheme pkgs).withHashtag;
        inherit (fleet.theming) cursor;
        inherit (moduleSettings) monitors;
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
      in
        {
          inherit layout binds outputs workspaces animations recent-windows;
          inherit (rules) layer-rules window-rules;
        }
        // rules // extra // mouse
    );
  };
}
