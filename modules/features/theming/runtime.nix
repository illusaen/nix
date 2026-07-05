{
  helpers,
  inputs,
  lib,
  ...
}: {
  flake.modules.nixos.runtime-theming = {
    fleet,
    pkgs,
    user,
    ...
  }: let
    inherit (fleet) fonts themes wallpaper;
    inherit (fleet.theming) cursor gtk icon;
    profileStateDir = "\${XDG_STATE_HOME:-$HOME/.local/state}/nix-theme";
    base16Lib = pkgs.callPackage inputs.base16.lib {};
    gtkPackage = pkgs.local.${gtk.packageName};
    themeNames = builtins.attrNames themes.profiles;
    themeListFile = pkgs.writeText "nix-theme-list" (lib.concatStringsSep "\n" themeNames);
    themeListJson = builtins.toJSON themeNames;
    profileSubdirs = [
      "alacritty"
      "bat/themes"
      "gtk-3.0"
      "gtk-4.0"
      "noctalia"
      "qt5ct"
      "qt6ct"
      "zathura"
      "zed/themes"
    ];

    mkProfileLinkCommands = files:
      files
      |> lib.mapAttrsToList (target: source: ''
        ln -sfn ${lib.escapeShellArg source} "$out/${target}"
      '')
      |> lib.concatStringsSep "\n";

    mkGtkIni = profile: let
      isDark = profile.colorScheme == "dark";
      gtkIni =
        {
          gtk-font-name = "${fonts.sans.name} ${toString fonts.sizes.applications}";
          gtk-theme-name = gtk.name;
          gtk-icon-theme-name = icon.name;
          gtk-cursor-theme-name = cursor.name;
          gtk-cursor-theme-size = cursor.size;
          gtk-application-prefer-dark-theme =
            if isDark
            then true
            else null;
        }
        |> lib.filterAttrs (_: value: value != null)
        |> (settings: {Settings = settings;})
        |> helpers.toGtkIni;
    in
      pkgs.writeText "gtk-settings.ini" gtkIni;

    mkQtctConf = profile:
      pkgs.writeText "qtct.conf" ''
        [Appearance]
        color_scheme_path=${profile.colorScheme}.conf
        custom_palette=false
        icon_theme=${icon.name}
        standard_dialogs=default
        style=Fusion

        [Fonts]
        fixed="${fonts.mono.name},${toString fonts.sizes.applications},-1,5,50,0,0,0,0,0"
        general="${fonts.sans.name},${toString fonts.sizes.applications},-1,5,50,0,0,0,0,0"

        [Interface]
        activate_item_on_single_click=1
        buttonbox_layout=0
        cursor_flash_time=1000
        dialog_buttons_have_icons=1
        double_click_interval=400
        gui_effects=@Invalid()
        keyboard_scheme=2
        menus_have_icons=true
        show_shortcuts_in_context_menus=true
        stylesheets=@Invalid()
        toolbutton_style=4
        underline_shortcut=1
        wheel_scroll_lines=3
      '';

    mkAlacrittyToml = scheme:
      pkgs.writeText "alacritty.toml" ''
        [window]
        dynamic_padding = true

        [window.padding]
        x = 32
        y = 32

        [font]
        size = ${toString fonts.sizes.terminal}

        [font.normal]
        family = "${fonts.mono.name}"

        [selection]
        save_to_clipboard = true

        [colors.primary]
        foreground = "${scheme.withHashtag.base05}"
        background = "${scheme.withHashtag.base00}"
        bright_foreground = "${scheme.withHashtag.base07}"

        [colors.selection]
        text = "${scheme.withHashtag.base05}"
        background = "${scheme.withHashtag.base02}"

        [colors.cursor]
        text = "${scheme.withHashtag.base00}"
        cursor = "${scheme.withHashtag.base05}"

        [colors.normal]
        black = "${scheme.withHashtag.base00}"
        red = "${scheme.withHashtag.red}"
        green = "${scheme.withHashtag.green}"
        yellow = "${scheme.withHashtag.yellow}"
        blue = "${scheme.withHashtag.blue}"
        magenta = "${scheme.withHashtag.magenta}"
        cyan = "${scheme.withHashtag.cyan}"
        white = "${scheme.withHashtag.base05}"

        [colors.bright]
        black = "${scheme.withHashtag.base03}"
        red = "${scheme.withHashtag.bright-red}"
        green = "${scheme.withHashtag.bright-green}"
        yellow = "${scheme.withHashtag.bright-yellow}"
        blue = "${scheme.withHashtag.bright-blue}"
        magenta = "${scheme.withHashtag.bright-magenta}"
        cyan = "${scheme.withHashtag.bright-cyan}"
        white = "${scheme.withHashtag.base07}"
      '';

    mkZathurarc = scheme: let
      fontSize = fonts.sizes.applications;
      hexToRgba = color: opacity: let
        r = scheme."${color}-dec-r";
        g = scheme."${color}-dec-g";
        b = scheme."${color}-dec-b";
      in "rgba(${r},${g},${b},${toString opacity})";
    in
      pkgs.writeText "zathurarc" ''
        map <C-o> file_chooser
        set guioptions vcs
        set adjust-open width
        set statusbar-basename true
        set render-loading false
        set scroll-step 120
        set selection-clipboard clipboard
        set font "monospace normal ${toString fontSize}"
        set default-bg "${scheme.withHashtag.base00}"
        set default-fg "${scheme.withHashtag.base01}"
        set statusbar-fg "${scheme.withHashtag.base04}"
        set statusbar-bg "${scheme.withHashtag.base02}"
        set inputbar-bg "${scheme.withHashtag.base00}"
        set inputbar-fg "${scheme.withHashtag.base07}"
        set notification-bg "${scheme.withHashtag.base00}"
        set notification-fg "${scheme.withHashtag.base07}"
        set notification-error-bg "${scheme.withHashtag.base00}"
        set notification-error-fg "${scheme.withHashtag.base08}"
        set notification-warning-bg "${scheme.withHashtag.base00}"
        set notification-warning-fg "${scheme.withHashtag.base08}"
        set highlight-color "${hexToRgba "base0A" 0.5}"
        set highlight-active-color "${hexToRgba "base0D" 0.5}"
        set completion-bg "${scheme.withHashtag.base01}"
        set completion-fg "${scheme.withHashtag.base0D}"
        set completion-highlight-fg "${scheme.withHashtag.base07}"
        set completion-highlight-bg "${scheme.withHashtag.base0D}"
        set recolor-lightcolor "${scheme.withHashtag.base00}"
        set recolor-darkcolor "${scheme.withHashtag.base06}"
      '';

    mkProfile = name: profile: let
      scheme = base16Lib.mkSchemeAttrs profile.base16Theme;
      selectedWallpaper =
        if profile.wallpaper != null
        then profile.wallpaper
        else wallpaper.image;
      pxToPt = size: builtins.floor (size * 4 / 3 + 0.5);
      profileFiles = {
        "env" = pkgs.writeText "theme-env" ''
          THEME_NAME=${lib.escapeShellArg name}
          COLOR_SCHEME=${lib.escapeShellArg (
            if profile.colorScheme == "dark"
            then "prefer-dark"
            else "default"
          )}
          GTK_THEME=${lib.escapeShellArg gtk.name}
          ICON_THEME=${lib.escapeShellArg icon.name}
          CURSOR_THEME=${lib.escapeShellArg cursor.name}
          CURSOR_SIZE=${lib.escapeShellArg (toString cursor.size)}
          WALLPAPER=${lib.escapeShellArg (toString selectedWallpaper)}
        '';
        "alacritty/alacritty.toml" = mkAlacrittyToml scheme;
        "bat/config" = pkgs.writeText "bat-config" ''
          --theme="Base16"
          --italic-text=always
        '';
        "bat/themes/Base16.tmTheme" = scheme {
          template = ../base/shell-utils/bat/bat.tmTheme.mustache;
          extension = ".tmTheme";
        };
        "gtk-3.0/settings.ini" = mkGtkIni profile;
        "gtk-4.0/settings.ini" = mkGtkIni profile;
        "noctalia/config.toml" = pkgs.replaceVars ../desktop-shell/noctalia/noctalia-config.toml.template {
          mono = fonts.mono.name;
          sans = fonts.sans.name;
          main = "DP-2";
          secondary = "HDMI-A-2";
          image = selectedWallpaper;
          imageDirectory = wallpaper.directory;
          location = fleet.timeZone |> lib.splitString "/" |> lib.last;
        };
        "qt5ct/qt5ct.conf" = mkQtctConf profile;
        "qt6ct/qt6ct.conf" = mkQtctConf profile;
        "zathura/zathurarc" = mkZathurarc scheme;
        "zed/settings.json" = pkgs.writeText "zed-settings.json" (builtins.toJSON (import ../programs/dev/zed/_config.nix {
          inherit lib scheme;
          inherit (fonts) sans mono icon;
          sizeBuffer = pxToPt fonts.sizes.terminal;
          sizeUi = pxToPt fonts.sizes.desktop;
        }));
        "zed/themes/base24-theme.json" = scheme {
          template = ../programs/dev/zed/zed-base24.json.mustache;
          extension = ".json";
        };
      };
    in
      pkgs.runCommand "nix-theme-profile-${name}" {} ''
        mkdir -p ${lib.concatMapStringsSep " " (dir: ''"$out/${dir}"'') profileSubdirs}
        cp -rs ${lib.escapeShellArg "${gtkPackage}/share/libadwaita-themes"}/* "$out/gtk-4.0/" 2>/dev/null || true
        ${mkProfileLinkCommands profileFiles}
      '';

    profileDirs = lib.mapAttrs mkProfile themes.profiles;
    profilesPackage = pkgs.linkFarm "nix-theme-profiles" (
      lib.mapAttrsToList (name: path: {inherit name path;}) profileDirs
    );
    themeList = pkgs.writeShellApplication {
      name = "theme-list";
      runtimeInputs = [pkgs.coreutils];
      text = ''
        set -euo pipefail

        if [ "''${1:-}" = "--json" ]; then
          printf '%s\n' ${lib.escapeShellArg themeListJson}
          exit 0
        fi

        cat ${themeListFile}
      '';
    };

    themeCurrent = pkgs.writeShellApplication {
      name = "theme-current";
      runtimeInputs = [pkgs.coreutils];
      text = ''
        set -euo pipefail

        state_dir="${profileStateDir}"
        selected="$state_dir/selected"

        if [ -s "$selected" ]; then
          cat "$selected"
          exit 0
        fi

        if [ -e "$state_dir/current" ]; then
          basename "$(readlink -f "$state_dir/current")"
          exit 0
        fi

        exit 1
      '';
    };

    themeApply = pkgs.writeShellApplication {
      name = "theme-apply";
      runtimeInputs = with pkgs; [
        coreutils
        dconf
        glib
        gnugrep
        gnused
      ];
      text = ''
        set -euo pipefail

        dry_run=0
        if [ "''${1:-}" = "--dry-run" ]; then
          dry_run=1
          shift
        fi

        theme="''${1:-${themes.default}}"
        state_dir="${profileStateDir}"
        profile_root="''${NIX_THEME_PROFILE_DIR:-${profilesPackage}}"
        profile="$profile_root/$theme"

        if [ ! -d "$profile" ]; then
          echo "Unknown theme: $theme" >&2
          echo "Available themes:" >&2
          sed 's/^/  /' ${themeListFile} >&2
          exit 1
        fi

        if [ "$dry_run" = 1 ]; then
          echo "theme=$theme"
          echo "profile=$profile"
          echo "state_dir=$state_dir"
          exit 0
        fi

        mkdir -p "$state_dir"
        ln -sfn "$profile" "$state_dir/current.next"
        mv -Tf "$state_dir/current.next" "$state_dir/current"
        printf '%s\n' "$theme" > "$state_dir/selected"

        # shellcheck disable=SC1091
        . "$profile/env"

        mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/qt5ct" "$HOME/.config/qt6ct"
        ln -sfn "$state_dir/current/gtk-3.0/settings.ini" "$HOME/.config/gtk-3.0/settings.ini"
        rm -rf "$HOME/.config/gtk-4.0"
        ln -sfn "$state_dir/current/gtk-4.0" "$HOME/.config/gtk-4.0"
        ln -sfn "$state_dir/current/qt5ct/qt5ct.conf" "$HOME/.config/qt5ct/qt5ct.conf"
        ln -sfn "$state_dir/current/qt6ct/qt6ct.conf" "$HOME/.config/qt6ct/qt6ct.conf"

        if command -v gsettings >/dev/null 2>&1 && gsettings list-schemas 2>/dev/null | grep -qx org.gnome.desktop.interface; then
          gsettings set org.gnome.desktop.interface color-scheme "$COLOR_SCHEME" || true
          gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME" || true
          gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME" || true
          gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME" || true
          gsettings set org.gnome.desktop.interface cursor-size "uint32 $CURSOR_SIZE" || true
        fi

        if command -v systemctl >/dev/null 2>&1; then
          systemctl --user try-restart noctalia.service waybar.service 2>/dev/null || true
        fi
      '';
    };

    themeSelect = pkgs.writeShellApplication {
      name = "theme-select";
      runtimeInputs = [
        pkgs.fuzzel
        themeApply
      ];
      text = ''
        set -euo pipefail
        theme="$(cat ${themeListFile} | fuzzel --dmenu --prompt 'Theme: ')"
        [ -n "$theme" ] || exit 0
        exec theme-apply "$theme"
      '';
    };

    themeCycle = pkgs.writeShellApplication {
      name = "theme-cycle";
      runtimeInputs = [
        pkgs.coreutils
        themeApply
        themeCurrent
      ];
      text = ''
        set -euo pipefail

        direction="''${1:-next}"
        current="$(theme-current 2>/dev/null || true)"
        first=""
        previous=""
        selected=""

        while IFS= read -r theme; do
          [ -n "$theme" ] || continue
          [ -n "$first" ] || first="$theme"

          if [ "$direction" = "previous" ] || [ "$direction" = "prev" ]; then
            if [ "$theme" = "$current" ]; then
              selected="$previous"
              break
            fi
            previous="$theme"
          else
            if [ "$previous" = "$current" ]; then
              selected="$theme"
              break
            fi
            previous="$theme"
          fi
        done < ${themeListFile}

        if [ -z "$selected" ]; then
          if [ "$direction" = "previous" ] || [ "$direction" = "prev" ]; then
            selected="$previous"
          else
            selected="$first"
          fi
        fi

        exec theme-apply "$selected"
      '';
    };
  in {
    environment.systemPackages = [
      pkgs.fuzzel
      profilesPackage
      themeApply
      themeCurrent
      themeCycle
      themeList
      themeSelect
    ];
    environment.sessionVariables = {
      NIX_THEME_STATE_DIR = profileStateDir;
      QT_QPA_PLATFORMTHEME = "qt6ct";
      BAT_CONFIG_DIR = "${profileStateDir}/current/bat";
    };
    system.userActivationScripts.initializeRuntimeTheme = ''
      if [ "$USER" = ${lib.escapeShellArg user.name} ]; then
        ${lib.getExe themeApply} ${lib.escapeShellArg themes.default}
      fi
    '';
  };
}
