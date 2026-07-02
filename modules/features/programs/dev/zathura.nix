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
    lib,
    wlib,
    ...
  }: {
    imports = [wlib.wrapperModules.zathura];
    flags."--config-dir" = lib.mkForce {
      data = "\${NIX_THEME_STATE_DIR:-\${XDG_STATE_HOME:-$HOME/.local/state}/nix-theme}/current/zathura";
      esc-fn = wlib.escapeShellArgWithEnv;
    };
  };
}
