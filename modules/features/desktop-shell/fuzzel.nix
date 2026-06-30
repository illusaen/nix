{
  flake.modules.nixos.desktop-shell = {pkgs, ...}: {environment.systemPackages = [pkgs.local.fuzzel];};

  flake.fleetWrappers.fuzzel = {
    wlib,
    pkgs,
    fleet,
    ...
  }: {
    imports = [wlib.wrapperModules.fuzzel];
    settings = {
      main = {
        output = fleet.monitors.conn.main;
        font = let
          inherit (fleet.fonts) mono icon sizes;
          fontSize = toString sizes.applications;
        in "${mono.name}:size=${fontSize},${icon.name}:size=${fontSize}";
        use-bold = true;
        icon-theme = fleet.theming.icon.name;
        anchor = "top";
        y-margin = 64;
        lines = 12;
        minimal-lines = true;
        horizontal-pad = 24;
        vertical-pad = 16;
        inner-pad = 8;
      };
      colors = let
        scheme = fleet.base16.scheme pkgs;
      in {
        background = "${scheme.base00-hex}cc";
        text = "${scheme.base05-hex}ff";
        placeholder = "${scheme.base03-hex}ff";
        prompt = "${scheme.base05-hex}ff";
        input = "${scheme.base05-hex}ff";
        match = "${scheme.base0A-hex}ff";
        selection = "${scheme.base02-hex}ff";
        selection-text = "${scheme.base05-hex}ff";
        selection-match = "${scheme.base0A-hex}ff";
        counter = "${scheme.base06-hex}ff";
        border = "${scheme.base0D-hex}ff";
      };
    };
  };
}
