{
  imports = [];

  modules.nixos = {
    config,
    fleet,
    host,
    lib,
    options,
    pkgs,
    sources,
    user,
    ...
  }: let
    noctaliaModule = sources.noctalia.outPath + "/nix/nixos-module.nix";
    noctaliaPackage = pkgs.callPackage (sources.noctalia.outPath + "/nix/package.nix") {};
    base16Lib = import (sources.base16.outPath + "/lib") sources.fromYaml.outPath {
      inherit pkgs lib;
    };
    kdl = import ../../lib/kdl.nix {inherit lib;};
    scheme = (base16Lib.mkSchemeAttrs fleet.base16.theme).withHashtag;
    monitors = {
      main = host.monitors.main;
      secondary = host.monitors.secondary or null;
    };
    fontPackages = with pkgs; [
      font-awesome
      inter
      maple-mono.NF-CN-unhinted
      material-symbols
      monaspace
      noto-fonts-color-emoji
    ];
    desktopPackages = with pkgs;
      [
        ddcutil
        libheif
        local.misc-scripts
        local.niri-scripts
        nautilus
        pavucontrol
        playerctl
        xwayland-satellite
      ]
      ++ lib.optional (pkgs ? swaylock) pkgs.swaylock;
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
    imports = [
      noctaliaModule
    ];

    environment.systemPackages = fontPackages ++ desktopPackages;
    environment.pathsToLink = ["share/thumbnailers"];
    nixpkgs.overlays = [
      (_final: prev: {
        nautilus = prev.nautilus.overrideAttrs (nprev: {
          buildInputs =
            nprev.buildInputs
            ++ (with prev.gst_all_1; [
              gst-plugins-good
              gst-plugins-bad
            ]);
        });
      })
    ];

    fonts = {
      packages = fontPackages;
      fontconfig.defaultFonts = {
        monospace = [fleet.fonts.mono.name "Maple Mono NF CN"];
        serif = [fleet.fonts.sans.name];
        sansSerif = [fleet.fonts.sans.name];
        emoji = [fleet.fonts.emoji.name];
      };
      fontconfig.aliases = let
        fontNames =
          map (font: font.name)
          (builtins.attrValues (removeAttrs fleet.fonts ["sizes"]));
      in
        builtins.listToAttrs (
          map (name:
            lib.nameValuePair name {
              default = ["Font Awesome 7 Free"];
            })
          fontNames
        );
    };

    hardware = {
      bluetooth.settings.General.Experimental = true;
      i2c.enable = true;
    };

    programs = {
      dconf.enable = true;
      niri.enable = true;
      noctalia = {
        enable = true;
        package = noctaliaPackage;
        recommendedServices.enable = true;
        systemd.enable = true;
      };
      nautilus-open-any-terminal = {
        enable = true;
        terminal = "alacritty";
      };
    };

    services = {
      blueman.enable = true;
      gvfs.enable = true;
      libinput.enable = true;
      playerctld.enable = true;
      pulseaudio.enable = false;
      udisks2.enable = true;
      xserver.xkb.layout = "us";

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

      gnome.sushi.enable = true;
      pipewire = {
        enable = true;
        alsa = {
          enable = true;
          support32Bit = true;
        };
        pulse.enable = true;
      };
    };

    security.rtkit.enable = true;

    systemdAutostart = lib.mkIf (options ? systemdAutostart) [
      (let
        inherit (config.services.tailscale) package;
      in {
        inherit package;
        name = "tailscale-systray";
        exec = "${lib.getExe package} systray";
      })
    ];

    system.userActivationScripts.installNiriConfig = ''
      if [ "$USER" = ${lib.escapeShellArg user.name} ]; then
        mkdir -p "$HOME/.config/niri"
        install -m 0644 ${lib.escapeShellArg niriConfig} "$HOME/.config/niri/config.kdl"
      fi
    '';

    systemd.user.services.noctalia.environment.NOCTALIA_CONFIG_HOME = "%h/.local/state/nix-theme/current";

    persist.directories = [
      "/var/lib/bluetooth"
    ];

    nix.settings = {
      extra-substituters = [
        "https://niri.cachix.org"
        "https://noctalia.cachix.org"
      ];
      extra-trusted-public-keys = [
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      ];
    };
  };

  modules.darwin = {fleet, ...}: {
    system.activationScripts.setDesktopBackground = ''
      echo "Setting desktop background."
      osascript -e 'tell application "System Events" to tell every desktop to set picture to "${fleet.wallpaper.image}"'
    '';
  };
}
