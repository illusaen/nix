{
  lib,
  helpers,
  config,
  ...
}:

with lib;
let
  cfg = config.modules.fd;

in
{
  options.modules.fd = {
    enable = helpers.mkTrueOption "fd";
  };
  config = mkIf cfg.enable {
    programs.fd = {
      enable = true;
      hidden = true;
      ignores = [
        ".git"
        ".github"
        ".cache"
      ];
      extraOptions = [ "--follow" ];
    };
  };
}
