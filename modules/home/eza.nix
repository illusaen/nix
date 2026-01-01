{
  lib,
  helpers,
  config,
  ...
}:

with lib;
let
  cfg = config.modules.eza;

in
{
  options.modules.eza = {
    enable = helpers.mkTrueOption "eza";
  };
  config = mkIf cfg.enable {
    programs.eza = {
      enable = true;
      git = true;
      icons = "auto";
      enableFishIntegration = true;
    };
  };
}
