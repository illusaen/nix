# GitHub CLI
{
  config,
  lib,
  pkgs,
  helpers,
  ...
}:
let
  cfg = config.modules.gh;
in
{
  options.modules.gh = {
    enable = helpers.mkTrueOption "GitHub CLI";
  };

  config = lib.mkIf cfg.enable {
    programs.gh = {
      enable = true;
      extensions = with pkgs; [ gh-copilot ];
      settings = {
        git_protocol = "ssh";
        prompt = "enabled";
      };
    };
  };
}
