{ config, lib, pkgs, ... }:
{
  imports = [ ../default.nix ];
  home = {
    homeDirectory = "/Users/${config.home.username}";
  };
}
