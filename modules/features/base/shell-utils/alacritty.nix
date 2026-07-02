{
  flake.modules.generic.shell-utils = {pkgs, ...}: {environment.systemPackages = [pkgs.local.alacritty];};

  flake.fleetWrappers.alacritty = {
    lib,
    wlib,
    ...
  }: {
    imports = [wlib.wrapperModules.alacritty];
    flags."--config-file" = lib.mkForce {
      data = "\${NIX_THEME_STATE_DIR:-\${XDG_STATE_HOME:-$HOME/.local/state}/nix-theme}/current/alacritty/alacritty.toml";
      esc-fn = wlib.escapeShellArgWithEnv;
    };
  };
}
