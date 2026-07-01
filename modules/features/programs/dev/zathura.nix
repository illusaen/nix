{
  flake.modules.nixos.zathura = {
    pkgs,
    lib,
    ...
  }: {
    environment.systemPackages = [pkgs.local.zathura];
    xdg.mime.defaultApplications = let
      application = "org.pwmt.zathura.desktop";
      mimeTypes = [
        "application/pdf"
        "application/epub+zip"
        "application/postscript"
      ];
    in
      lib.genAttrs mimeTypes (_: application);
  };

  flake.fleetWrappers.zathura = {
    fleet,
    wlib,
    pkgs,
    ...
  }: let
    scheme = fleet.base16.scheme pkgs;
    fontSize = fleet.fonts.sizes.applications;
    hexToRgba = color: opacity: let
      r = scheme."${color}-dec-r";
      g = scheme."${color}-dec-g";
      b = scheme."${color}-dec-b";
    in "rgba(${r},${g},${b},${toString opacity})";
  in {
    imports = [wlib.wrapperModules.zathura];
    mappings = {
      "<C-o>" = "file_chooser";
    };
    settings = with scheme.withHashtag; {
      guioptions = "vcs";
      adjust-open = "width";
      statusbar-basename = true;
      render-loading = false;
      scroll-step = 120;
      selection-clipboard = "clipboard";
      font = "monospace normal ${toString fontSize}";
      default-bg = base00;
      default-fg = base01;
      statusbar-fg = base04;
      statusbar-bg = base02;
      inputbar-bg = base00;
      inputbar-fg = base07;
      notification-bg = base00;
      notification-fg = base07;
      notification-error-bg = base00;
      notification-error-fg = base08;
      notification-warning-bg = base00;
      notification-warning-fg = base08;
      highlight-color = hexToRgba "base0A" 0.5;
      highlight-active-color = hexToRgba "base0D" 0.5;
      completion-bg = base01;
      completion-fg = base0D;
      completion-highlight-fg = base07;
      completion-highlight-bg = base0D;
      recolor-lightcolor = base00;
      recolor-darkcolor = base06;
    };
  };
}
