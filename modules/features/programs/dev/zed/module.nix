{
  flake.modules.generic.zed = {pkgs, ...}: {environment.systemPackages = [pkgs.local.zed];};

  flake.fleetWrappers.zed = {
    wlib,
    pkgs,
    ...
  }: let
    dataDir = "\${XDG_DATA_HOME:-$HOME/.local/share}/zed-wrapped";
    themeDir = "\${NIX_THEME_STATE_DIR:-\${XDG_STATE_HOME:-$HOME/.local/state}/nix-theme}/current/zed";
  in {
    imports = [wlib.modules.default];
    flags."--user-data-dir" = {
      data = dataDir;
      esc-fn = wlib.escapeShellArgWithEnv;
    };
    binName = "zeditor";
    package = pkgs.zed-editor;
    runShell = [
      ''
        zed_data_dir=${wlib.escapeShellArgWithEnv dataDir}
        theme_dir=${wlib.escapeShellArgWithEnv themeDir}
        ${pkgs.coreutils}/bin/mkdir -p "$zed_data_dir/config/themes"
        ${pkgs.coreutils}/bin/rm -f "$zed_data_dir/settings.json" "$zed_data_dir/themes/base24-theme.json"
        ${pkgs.coreutils}/bin/ln -s "$theme_dir/settings.json" "$zed_data_dir/config/settings.json"
        ${pkgs.coreutils}/bin/ln -s "$theme_dir/themes/base24-theme.json" "$zed_data_dir/config/themes/base24-theme.json"
      ''
    ];
  };
}
