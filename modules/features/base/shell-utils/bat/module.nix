{
  flake.modules.generic.shell-utils = {pkgs, ...}: {
    environment.systemPackages = [pkgs.local.bat];
  };

  flake.modules.nixos.bat = {
    lib,
    pkgs,
    ...
  }: {
    system.userActivationScripts.rebuildBatCache = ''
      echo "Rebuilding bat cache."
      ${lib.getExe pkgs.local.bat} cache --build
    '';
  };

  flake.wrappers.bat = {
    wlib,
    pkgs,
    ...
  }: {
    imports = [wlib.modules.default];
    package = pkgs.bat;
    env.BAT_CONFIG_DIR = "\${NIX_THEME_STATE_DIR:-\${XDG_STATE_HOME:-$HOME/.local/state}/nix-theme}/current/bat";
  };
}
