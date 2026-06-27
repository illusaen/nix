top: {
  flake.modules.generic.shell-utils = {pkgs, ...}: {
    environment.systemPackages = [pkgs.local.bat];
  };

  flake.wrappers.bat = {
    wlib,
    lib,
    pkgs,
    config,
    ...
  }: {
    imports = [wlib.modules.default];
    package = pkgs.bat;
    env.BAT_CONFIG_DIR = dirOf config.constructFiles.generatedConfig.path;
    constructFiles.generatedConfig = {
      content = ''
        --theme="Base16"
        --italic-text=always
      '';
      relPath = "config";
    };
    constructFiles.themeConfig = let
      scheme = top.config.base16.scheme pkgs;
      bat-theme = scheme {
        template = ./bat.tmTheme.mustache;
        extension = ".tmTheme";
      };
    in {
      relPath = "themes/Base16.tmTheme";
      builder = ''
        ln -s ${lib.escapeShellArg bat-theme} "$2"
      '';
    };
  };
}
