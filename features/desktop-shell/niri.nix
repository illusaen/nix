{
  modules.nixos = {
    config,
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
    kdl = import ../../lib/kdl.nix {inherit lib;};
    scheme = (base16Lib.mkSchemeAttrs fleet.base16.theme).withHashtag;
    monitors = {
      main = host.monitors.main;
      secondary = host.monitors.secondary or null;
    };
    sddmExtraPackages = with pkgs; [
      qt6.qt5compat
      sddmTheme
      weston
    ];
    sddmTheme = pkgs.where-is-my-sddm-theme.override {
      themeConfig.General = {
        background = toString fleet.wallpaper.image;
        passwordCursorColor = scheme.base0D;
      };
    };
    niriRules = import ../../modules/features/desktop-shell/niri/_rules.nix;
    niriMouse = import ../../modules/features/desktop-shell/niri/_mouse.nix {
      cursor = removeAttrs fleet.theming.cursor ["packageName"];
    };
    niriSettings =
      {
        animations = import ../../modules/features/desktop-shell/niri/_animations.nix;
        binds = import ../../modules/features/desktop-shell/niri/_binds.nix;
        inherit (niriMouse) cursor input;
        layout = import ../../modules/features/desktop-shell/niri/_layout.nix {inherit scheme;};
        outputs = import ../../modules/features/desktop-shell/niri/_outputs.nix {inherit lib monitors;};
        recent-windows = import ../../modules/features/desktop-shell/niri/_window-switcher.nix {highlightColor = scheme.base0D;};
        workspaces = import ../../modules/features/desktop-shell/niri/_workspaces.nix {inherit lib monitors;};
        inherit (niriRules) layer-rules window-rules;
      }
      // import ../../modules/features/desktop-shell/niri/_extra.nix;
    niriConfig = pkgs.writeText "niri-config.kdl" (kdl.renderNiri niriSettings);
  in {
    environment.systemPackages = with pkgs; [xwayland-satellite local.niri-scripts];
    programs.niri.enable = true;

    services = {
      displayManager = {
        enable = true;
        defaultSession = "niri";
        sddm = {
          enable = true;
          enableHidpi = true;
          extraPackages = sddmExtraPackages;
          theme = "${sddmTheme}/share/sddm/themes/where_is_my_sddm_theme";
          wayland = {
            enable = true;
            compositor = "weston";
            compositorCommand = let
              westonIni = (pkgs.formats.ini {}).generate "weston.ini" (
                {
                  libinput = {
                    enable-tap = config.services.libinput.mouse.tapping;
                    left-handed = config.services.libinput.mouse.leftHanded;
                  };
                  keyboard = let
                    xcfg = config.services.xserver;
                  in {
                    keymap_model = xcfg.xkb.model;
                    keymap_layout = xcfg.xkb.layout;
                    keymap_variant = xcfg.xkb.variant;
                    keymap_options = xcfg.xkb.options;
                  };
                }
                // lib.optionalAttrs ((host.monitors.secondary or null) != null) {
                  output = {
                    name = host.monitors.secondary;
                    mode = "off";
                  };
                }
              );
            in "${lib.getExe pkgs.weston} --shell=kiosk -c ${westonIni}";
          };
        };
      };
    };

    system.userActivationScripts.installNiriConfig = ''
      if [ "$USER" = ${lib.escapeShellArg user.name} ]; then
        mkdir -p "$HOME/.config/niri"
        install -m 0644 ${lib.escapeShellArg niriConfig} "$HOME/.config/niri/config.kdl"
      fi
    '';

    nix.settings = {
      extra-substituters = [
        "https://niri.cachix.org"
      ];
      extra-trusted-public-keys = [
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      ];
    };
  };
}
