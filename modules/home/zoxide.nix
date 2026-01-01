{
  lib,
  helpers,
  config,
  ...
}:

with lib;
let
  cfg = config.modules.zoxide;

in
{
  options.modules.zoxide = {
    enable = helpers.mkTrueOption "zoxide";
  };
  config = mkIf cfg.enable {
    programs.zoxide = {
      enable = true;
      enableFishIntegration = true;
      options = [ "--cmd j" ];
    };
  };
}
