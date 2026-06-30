{
  wlib,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    wlib.modules.default
    ../service.nix
  ];
  options = {
    font = lib.mkOption {type = lib.types.str;};
    fontSize = lib.mkOption {type = lib.types.int;};
    scheme = lib.mkOption {type = lib.types.raw;};
    settings = lib.mkOption {
      type = wlib.types.structuredValueWith {typeName = "JSON";};
      default = {};
      description = ''
        SwayNC configuration settings.
      '';
    };
    configFile = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.path = config.constructFiles.generatedConfig.path;
      default.content = "";
      description = ''
        SwayNC configuration settings file.
      '';
    };
    "style.css" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.path = config.constructFiles.generatedStyle.path;
      default.content = "";
      description = "CSS style for SwayNC.";
    };
  };

  config.service.enable = true;
  config.settings = {
    positionX = "center";
    positionY = "bottom";
    layer = "overlay";
    layer-shell = true;
    layer-shell-cover-screen = false;
    cssPriority = "user";
    control-center-positionX = "right";
    control-center-positionY = "top";
    control-center-width = 520;
    control-center-margin-top = 0;
    control-center-margin-bottom = 0;
    control-center-margin-right = 0;
    control-center-margin-left = 0;
    notification-2fa-action = true;
    notification-inline-replies = false;
    notification-window-width = 380;
    notification-icon-size = 48;
    notification-body-image-height = 240;
    notification-body-image-width = 240;
    image-visibility = "when-available";
    hide-on-clear = true;
    widgets = [
      "mpris"
      "volume"
      "title"
      "notifications"
      "buttons-grid"
    ];
    widget-config = {
      title.button-text = "Clear";
      mpris = {
        show-album-art = false;
        autohide = true;
        loop-carousel = true;
      };
      volume = {
        label = "";
        step = 5;
      };
      buttons-grid.actions = [
        {
          label = "󰂛";
          command = "${placeholder "out"}/bin/swaync-client -d";
          tooltip = "DND";
        }
        {
          label = "";
          command = "${lib.getExe pkgs.pavucontrol}";
          tooltip = "Audio";
        }
        {
          label = "";
          command = "${pkgs.blueman}/bin/blueman-manager";
          tooltip = "Bluetooth";
        }
        {
          label = "";
          command = "${lib.getExe pkgs.local.swaylock}";
          tooltip = "Lock";
        }
        {
          label = "󰜉";
          command = "reboot";
          tooltip = "Reboot";
        }
        {
          label = "⏻";
          command = "shutdown now";
          tooltip = "Power off";
        }
      ];
    };
  };
  config."style.css".content = with config.scheme.withHashtag;
    ''
      * {
          font-family: "${config.font}";
          font-size: ${toString config.fontSize}pt;
      }
      @define-color base00 ${base00}; @define-color base01 ${base01};
      @define-color base02 ${base02}; @define-color base03 ${base03};
      @define-color base04 ${base04}; @define-color base05 ${base05};
      @define-color base06 ${base06}; @define-color base07 ${base07};

      @define-color base08 ${base08}; @define-color base09 ${base09};
      @define-color base0A ${base0A}; @define-color base0B ${base0B};
      @define-color base0C ${base0C}; @define-color base0D ${base0D};
      @define-color base0E ${base0E}; @define-color base0F ${base0F};
    ''
    + (builtins.readFile ./base.css);
  config.package = pkgs.swaynotificationcenter.overrideAttrs (old: {
    postPatch =
      (old.postPatch or "")
      + ''
        substituteInPlace src/controlCenter/widgets/mpris/mpris.vala \
          --replace-fail \
            'set_orientation (Gtk.Orientation.VERTICAL);' \
            'set_orientation (Gtk.Orientation.VERTICAL); set_hexpand (true);' \
          --replace-fail \
            'carousel_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {' \
            'carousel_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) { hexpand = true,' \
          --replace-fail \
            'carousel = new Adw.Carousel () {' \
            'carousel = new Adw.Carousel () { hexpand = true,'
      '';
  });
  config.flags = {
    "--config" = config.configFile.path;
    "--style" = config."style.css".path;
  };
  config.constructFiles.generatedStyle = {
    content = config."style.css".content or "";
    relPath = "${config.binName}-style.css";
  };
  config.constructFiles.generatedConfig = {
    content =
      if config.configFile.content or "" != ""
      then config.configFile.content
      else builtins.toJSON config.settings;
    relPath = "${config.binName}-config.json";
  };
}
