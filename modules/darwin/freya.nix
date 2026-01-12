{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.modules.freyja;
in
{
  options.modules.freyja = {
    enable = lib.mkEnableOption "freyja darwin configuration";
  };

  config = lib.mkIf cfg.enable {
    services.onepassword-secrets.groupId = 600;
  };
}
