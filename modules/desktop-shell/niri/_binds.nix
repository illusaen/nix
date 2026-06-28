{
  "Mod+Shift+Slash" = _: {
    content.show-hotkey-overlay = _: {};
  };
  "Alt+Shift+4" = _: {
    content.screenshot = _: {};
  };

  ## Programs
  "Alt+Shift+T" = _: {
    props.hotkey-overlay-title = "Toggle Terminal";
    content.spawn-sh = "ndrop --app-id '^ndrop-alacritty$' --name alacritty -- alacritty --class ndrop-alacritty";
  };
  "Mod+T" = _: {
    props.hotkey-overlay-title = "Terminal";
    content.spawn = "alacritty";
  };
  "Ctrl+Space" = _: {
    props.hotkey-overlay-title = "Launcher";
    content.spawn = "fuzzel";
  };
  "Mod+Shift+L" = _: {
    props.hotkey-overlay-title = "Lock Screen";
    content.spawn = "swaylock";
  };
  "Mod+S" = _: {
    props.hotkey-overlay-title = "Notification Center";
    content.spawn-sh = "swaync-client -t -sw";
  };

  "Mod+Ctrl+Space" = _: {
    props.hotkey-overlay-title = "Power Menu";
    content.spawn-sh = "rofi-power-menu";
  };
  "Ctrl+Alt+Space" = _: {
    props.hotkey-overlay-title = "Calculator";
    content.spawn-sh = "rofi-calculator";
  };

  ## Monitor Brightness
  "Mod+Ctrl+B" = _: {
    props.hotkey-overlay-title = "Brightness +";
    content.spawn-sh = "monitor-brightness up";
  };
  "Mod+Ctrl+Shift+B" = _: {
    props.hotkey-overlay-title = "Brightness -";
    content.spawn-sh = "monitor-brightness down";
  };
  "XF86MonBrightnessUp" = _: {
    props.hotkey-overlay-title = "Brightness +";
    content.spawn-sh = "monitor-brightness up";
  };
  "XF86MonBrightnessDown" = _: {
    props.hotkey-overlay-title = "Brightness -";
    content.spawn-sh = "monitor-brightness down";
  };

  ## Media
  "XF86AudioRaiseVolume" = _: {
    props = [
      {hotkey-overlay-title = "Vol +";}
      {allow-when-locked = true;}
    ];
    content.spawn-sh = "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+";
  };
  "XF86AudioLowerVolume" = _: {
    props = [
      {hotkey-overlay-title = "Vol -";}
      {allow-when-locked = true;}
    ];
    content.spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
  };
  "XF86AudioMute" = _: {
    props = [
      {hotkey-overlay-title = "Mute";}
      {allow-when-locked = true;}
    ];
    content.spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
  };
  "XF86AudioMicMute" = _: {
    props = [
      {hotkey-overlay-title = "Mic Mute";}
      {allow-when-locked = true;}
    ];
    content.spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
  };
  "XF86AudioNext" = _: {
    props = [
      {hotkey-overlay-title = "Playerctl →";}
      {allow-when-locked = true;}
    ];
    content.spawn-sh = "playerctl next";
  };
  "XF86AudioPlay" = _: {
    props = [
      {hotkey-overlay-title = "Playerctl play/pause";}
      {allow-when-locked = true;}
    ];
    content.spawn-sh = "playerctl play-pause";
  };
  "XF86AudioPrev" = _: {
    props = [
      {hotkey-overlay-title = "Playerctl ←";}
      {allow-when-locked = true;}
    ];
    content.spawn-sh = "playerctl previous";
  };

  "Mod+Q" = _: {
    props.repeat = false;
    content.close-window = _: {};
  };
  "Mod+O" = _: {
    props.repeat = false;
    content.toggle-overview = _: {};
  };

  "Mod+Up" = _: {
    props.hotkey-overlay-title = "Focus Window/Workspace ↑";
    content.spawn-sh = "niri-workspace up";
  };
  "Mod+Down" = _: {
    props.hotkey-overlay-title = "Focus Window/Workspace ↓";
    content.spawn-sh = "niri-workspace down";
  };
  "Mod+Left" = _: {
    content.focus-column-left = _: {};
  };
  "Mod+Right" = _: {
    content.focus-column-right = _: {};
  };

  "Mod+Ctrl+Left" = _: {
    content.move-column-left = _: {};
  };
  "Mod+Ctrl+Down" = _: {
    content.move-window-down-or-to-workspace-down = _: {};
  };
  "Mod+Ctrl+Up" = _: {
    content.move-window-up-or-to-workspace-up = _: {};
  };
  "Mod+Ctrl+Right" = _: {
    content.move-column-right = _: {};
  };

  "Mod+Home" = _: {
    content.focus-column-first = _: {};
  };
  "Mod+End" = _: {
    content.focus-column-last = _: {};
  };
  "Mod+Ctrl+Home" = _: {
    content.move-column-to-first = _: {};
  };
  "Mod+Ctrl+End" = _: {
    content.move-column-to-last = _: {};
  };

  "Mod+Shift+Left" = _: {
    content.focus-monitor-left = _: {};
  };
  "Mod+Shift+Right" = _: {
    content.focus-monitor-right = _: {};
  };

  "Mod+Ctrl+Shift+Left" = _: {
    content.move-column-to-monitor-left = _: {};
  };
  "Mod+Ctrl+Shift+Right" = _: {
    content.move-column-to-monitor-right = _: {};
  };
  "Mod+Alt+Shift+Left" = _: {
    content.move-workspace-to-monitor-left = _: {};
  };
  "Mod+Alt+Shift+Right" = _: {
    content.move-workspace-to-monitor-right = _: {};
  };

  "Mod+WheelScrollUp" = _: {
    props = { hotkey-overlay-title = "Focus Window/Workspace ↑"; cooldown-ms = 150; };
    content.spawn-sh = "niri-workspace up";
  };
  "Mod+WheelScrollDown" = _: {
    props = { hotkey-overlay-title = "Focus Window/Workspace ↓"; cooldown-ms = 150; };
    content.spawn-sh = "niri-workspace down";
  };
  "Mod+Ctrl+WheelScrollUp" = _: {
    props.cooldown-ms = 150;
    content.move-column-to-workspace-up = _: {};
  };
  "Mod+Ctrl+WheelScrollDown" = _: {
    props.cooldown-ms = 150;
    content.move-column-to-workspace-down = _: {};
  };

  "Mod+Shift+WheelScrollUp" = _: {
    props.cooldown-ms = 150;
    content.focus-column-left = _: {};
  };
  "Mod+Shift+WheelScrollDown" = _: {
    props.cooldown-ms = 150;
    content.focus-column-right = _: {};
  };
  "Mod+Ctrl+Shift+WheelScrollUp" = _: {
    props.cooldown-ms = 150;
    content.move-column-left = _: {};
  };
  "Mod+Ctrl+Shift+WheelScrollDown" = _: {
    props.cooldown-ms = 150;
    content.move-column-right = _: {};
  };

  "Mod+BracketLeft" = _: { content.consume-or-expel-window-left = _: {}; };
    "Mod+BracketRight" = _: { content.consume-or-expel-window-right = _: {}; };
    "Mod+Comma" = _: {
      content.consume-window-into-column = _: {};
    };
    "Mod+Period" = _: {
      content.expel-window-from-column = _: {};
    };

    "Mod+R" = _: {
      content.switch-preset-column-width = _: {};
    };
    "Mod+Shift+R" = _: {
      content.switch-preset-column-width-back = _: {};
    };

    "Mod+Ctrl+Shift+R" = _: {
      content.switch-preset-window-height = _: {};
    };
    "Mod+Ctrl+R" = _: {
      content.reset-window-height = _: {};
    };

    "Mod+F" = _: {
      content.maximize-column = _: {};
    };
    "Mod+Shift+F" = _: {
      content.fullscreen-window = _: {};
    };

  "Mod+C" = _: {
    content.center-column = _: {};
  };
  "Mod+Ctrl+C" = _: {
    content.center-visible-columns = _: {};
  };

  "Mod+V" = _: {
    content.toggle-window-floating = _: {};
  };
  "Mod+Shift+V" = _: {
    content.switch-focus-between-floating-and-tiling = _: {};
  };

  "Mod+W" = _: {
    content.toggle-column-tabbed-display = _: {};
  };
  "Mod+Escape" = _: {
    props.allow-inhibiting = false;
    content.toggle-keyboard-shortcuts-inhibit = _: {};
  };

  "Mod+Shift+P" = _: {
    content.power-off-monitors = _: {};
  };
  "Ctrl+Alt+Delete" = _: {
    content.quit = _: {};
  };
}
