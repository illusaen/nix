{
  pkgs,
  lib,
  config,
  vars,
  ...
}:

with lib;
let
  cfg = config.modules.git;
  inherit (vars) name fullName;

in
{
  options.modules.git = {
    enable = mkEnableOption "git" // {
      default = true;
    };
  };
  config = mkIf cfg.enable {
    programs.git = {
      enable = true;
      settings = {
        user.name = fullName;
        user.email = "jaewchen@gmail.com";
        init.defaultBranch = "main";
        core.excludesfile = "$NIXOS_CONFIG_DIR/scripts/gitignore";
      };
    };
  };
}
