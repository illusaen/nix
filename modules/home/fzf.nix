{
  config,
  lib,
  helpers,
  pkgs,
  vars,
  ...
}:
let
  cfg = config.modules.fzf;
in
{
  options.modules.fzf = {
    enable = helpers.mkTrueOption "fzf";
  };

  config = lib.mkIf cfg.enable {
    programs.fzf = {
      enable = true;
      enableFishIntegration = false;
      defaultOptions = [
        "--height 40%"
        "--style full"
        "--color dark"
        "--color=fg:-1,bg:-1,hl:#5fff87,fg+:-1,bg+:-1,hl+:#ffaf5f"
        "--color=info:#af87ff,prompt:#5fff87,pointer:#ff87d7,marker:#ff87d7,spinner:#ff87d7"
      ];
    };
  };
}
