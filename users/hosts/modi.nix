{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ../default.nix ];
  home = {
    homeDirectory = "/home/${config.home.username}";
  };
}
