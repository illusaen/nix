top: let
  topConfig = top.config;
in {
  flake.modules.nixos.display-manager = {
    pkgs,
    lib,
    config,
    ...
  }: {
    environment.systemPackages = with pkgs.qt6; [qt5compat];
    services.displayManager = {
      enable = true;
      defaultSession = "niri";
      sddm = {
        enable = true;
        wayland = {
          enable = true;
          compositor = "weston";
          compositorCommand = let
            weston-ini = (pkgs.formats.ini {}).generate "weston.ini" {
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
              output = {
                name = topConfig.fleet.monitors.conn.secondary;
                mode = "off";
              };
            };
          in "${lib.getExe pkgs.weston} --shell=kiosk -c ${weston-ini}";
        };
        enableHidpi = true;
        theme = "${pkgs.where-is-my-sddm-theme}/share/sddm/themes/where_is_my_sddm_theme";
      };
    };
  };
}
