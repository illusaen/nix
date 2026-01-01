# Bat - cat with syntax highlighting
{
  config,
  lib,
  helpers,
  ...
}:
let
  cfg = config.modules.bat;
in
{
  options.modules.bat = {
    enable = helpers.mkTrueOption "bat";
  };

  config = lib.mkIf cfg.enable {
    programs.bat = {
      enable = true;
      config.theme = "Dracula";
    };
  };
}
