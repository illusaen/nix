{
  flake.modules.nixos.display-manager = {
    pkgs,
    lib,
    config,
    fleet,
    host,
    ...
  }: let
    sddmTheme = pkgs.where-is-my-sddm-theme.override {
      themeConfig.General = {
        background = toString fleet.wallpaper.image;
        passwordCursorColor = (fleet.base16.scheme pkgs).withHashtag.base0D;
      };
    };
  in {
    services.displayManager = {
      enable = true;
      defaultSession = "niri";
      sddm = {
        enable = true;
        extraPackages = with pkgs; [qt6.qt5compat sddmTheme];
        wayland = {
          enable = true;
          compositor = "weston";
          compositorCommand = let
            weston-ini = (pkgs.formats.ini {}).generate "weston.ini" (
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
              // lib.optionalAttrs (host.monitors.secondary != null) {
                output = {
                  name = host.monitors.secondary;
                  mode = "off";
                };
              }
            );
          in "${lib.getExe pkgs.weston} --shell=kiosk -c ${weston-ini}";
        };
        enableHidpi = true;
        theme = "${sddmTheme}/share/sddm/themes/where_is_my_sddm_theme";
      };
    };
  };
}
