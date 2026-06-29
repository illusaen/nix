top: {
  flake.modules.generic.zed = {pkgs, ...}: {environment.systemPackages = [pkgs.local.zed];};

  flake.wrappers.zed = {
    wlib,
    lib,
    pkgs,
    config,
    ...
  }: let
    topConfig = top.config;
    dataDir = "\${XDG_DATA_HOME:-$HOME/.local/share}/zed-wrapped";
    scheme = topConfig.fleet.base16.scheme pkgs;
  in {
    imports = [wlib.modules.default];
    flags."--user-data-dir" = {
      data = dataDir;
      esc-fn = wlib.escapeShellArgWithEnv;
    };
    binName = "zeditor";
    package = pkgs.zed-editor;
    constructFiles.generatedConfig = {
      relPath = "settings.json";
      content = builtins.toJSON (import ./_config.nix (let
        pxToPt = s: builtins.floor (s * 4 / 3 + 0.5);
        inherit (topConfig.fleet.fonts.sizes) terminal desktop;
      in {
        inherit lib scheme;
        inherit (topConfig.fleet.fonts) sans mono icon;
        sizeBuffer = pxToPt terminal;
        sizeUi = pxToPt desktop;
      }));
    };
    constructFiles.generatedTheme = let
      theme = scheme {
        template = ./zed-base24.json.mustache;
        extension = ".json";
      };
    in {
      relPath = "themes/base24-theme.json";
      builder = ''
        mkdir -p "$(dirname "$2")"
        ln -s ${lib.escapeShellArg theme} "$2"
      '';
    };
    runShell = [
      ''
        zed_data_dir=${wlib.escapeShellArgWithEnv dataDir}
        ${pkgs.coreutils}/bin/mkdir -p "$zed_data_dir/config/themes"
        ${pkgs.coreutils}/bin/rm -f "$zed_data_dir/settings.json" "$zed_data_dir/themes/base24-theme.json"
        ${pkgs.coreutils}/bin/install -m 0644 ${lib.escapeShellArg config.constructFiles.generatedConfig.path} "$zed_data_dir/config/settings.json"
        ${pkgs.coreutils}/bin/install -m 0644 ${lib.escapeShellArg config.constructFiles.generatedTheme.path} "$zed_data_dir/config/themes/base24-theme.json"
      ''
    ];
  };
}
