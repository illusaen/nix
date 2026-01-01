{
  pkgs,
  lib,
  config,
  vars,
  ...
}:

with lib;
let
  cfg = config.modules.direnv;
  inherit (vars) dirs;

in
{
  options.modules.direnv = {
    enable = lib.mkEnableOption "direnv" // {
      default = true;
    };
  };
  config = mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      silent = true;
      nix-direnv.enable = true;
      config = {
        hide_env_diff = true;
        whitelist.prefix = [ "${dirs.projects}" ];
      };
    };
  };
}
