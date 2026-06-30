{
  flake.modules.nixos.fuzzel = {
    pkgs,
    lib,
    ...
  }: let
    mkHiddenDesktopEntries = entries: (pkgs.stdenvNoCC.mkDerivation {
      name = "hidden-desktop-entries";
      meta.priority = 1;
      phases = ["buildPhase" "installPhase"];
      buildPhase =
        entries
        |> map (e: "echo -e \"[Desktop Entry]\nNoDisplay=true\n\" > ${e}.desktop")
        |> (lib.concatStringsSep "\n");
      installPhase = ''
        mkdir -p $out/share/applications
        mv *.desktop $out/share/applications
      '';
    });
  in {
    environment.systemPackages = [
      pkgs.local.fuzzel
      (mkHiddenDesktopEntries ["blueman-adapters" "nixos-manual" "Alacritty" "gvim" "vim"])
    ];
  };

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
