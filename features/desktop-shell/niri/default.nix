{
  modules.nixos = {
    fleet,
    host,
    lib,
    pkgs,
    sources,
    user,
    ...
  }: let
    base16Lib = import (sources.base16.outPath + "/lib") sources.fromYaml.outPath {
      inherit pkgs lib;
    };
    scheme = base16Lib.mkSchemeAttrs fleet.base16.theme;
    inherit (fleet.theming) cursor;
  in {
    environment.systemPackages = with pkgs; [xwayland-satellite local.niri-scripts];
    programs.niri.enable = true;

    nix.settings = {
      extra-substituters = [
        "https://niri.cachix.org"
      ];
      extra-trusted-public-keys = [
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      ];
    };

    hjem.users.${user.name}.xdg = {
      config.files =
        {
          "niri/niri-host.kdl".source = pkgs.replaceVars ./niri-host.kdl {
            cursor = cursor.name;
            cursorSize = cursor.size;
            main = host.monitors.main;
            secondary = host.monitors.secondary or host.monitors.main;
          };
          "niri/niri-config.kdl".source = ./niri-config.kdl;
        }
        // lib.optionalAttrs (host.monitors.secondary != null) {
          "niri/niri-monitors.kdl".text = ''
            "output" "${host.monitors.secondary}" {
              "hot-corners"  {
                "off"
              }
              "position" "x"=5120 "y"=120
              "scale" 1
              "transform" "270"
            }
          '';
        };
      state.files."nix-theme/niri-colors.kdl".source = pkgs.replaceVars ./niri-colors.kdl {
        inherit (scheme) base00 base02 base03 base08 base12 base15 base0C base0D;
      };
    };
  };
}
