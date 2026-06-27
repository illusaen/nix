_top: {
  flake.modules.generic.shell-utils = {pkgs, ...}: {environment.systemPackages = [pkgs.local.bat];};

  flake.wrappers = {
    bat = {
      wlib,
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
      # constructFiles.themeConfig = let
      #   bat-theme = top.config.scheme {
      #     template = ./bat.tmTheme.mustache;
      #     extension = "tmTheme";
      #   };
      # in {
      #   relPath = "themes/Base16.tmTheme";
      #   builder = ''
      #     mkdir -p "$(dirname "$2")"
      #     ln -s ${lib.escapeShellArg bat-theme} "$2"
      #   '';
      # };
    };
  };
}
