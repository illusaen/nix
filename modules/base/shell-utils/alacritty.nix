{config, ...}: {
  flake.modules.generic.shell-utils = {pkgs, ...}: {environment.systemPackages = [pkgs.local.alacritty];};

  flake.wrappers.alacritty = {
    wlib,
    pkgs,
    ...
  }: {
    imports = [wlib.wrapperModules.alacritty];
    settings = {
      window = {
        padding = {
          x = 32;
          y = 32;
        };
        dynamic_padding = true;
      };
      font = let
        inherit (config.fleet) fonts;
      in {
        normal.family = fonts.mono;
        size = fonts.sizes.terminal;
      };
      colors = let
        scheme = config.fleet.base16.scheme pkgs;
        inherit (scheme) withHashtag;
      in {
        primary = {
          foreground = withHashtag.base05;
          background = withHashtag.base00;
          bright_foreground = withHashtag.base07;
        };
        selection = {
          text = withHashtag.base05;
          background = withHashtag.base02;
        };
        cursor = {
          text = withHashtag.base00;
          cursor = withHashtag.base05;
        };
        normal = {
          black = withHashtag.base00;
          white = withHashtag.base05;
          inherit
            (withHashtag)
            red
            green
            yellow
            blue
            magenta
            cyan
            ;
        };
        bright = {
          black = withHashtag.base03;
          white = withHashtag.base07;
          red = withHashtag.bright-red;
          green = withHashtag.bright-green;
          yellow = withHashtag.bright-yellow;
          blue = withHashtag.bright-blue;
          magenta = withHashtag.bright-magenta;
          cyan = withHashtag.bright-cyan;
        };
      };
      selection.save_to_clipboard = true;
    };
  };
}
