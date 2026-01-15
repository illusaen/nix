# Base Darwin module - core configurations enabled by default
{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf pkgs.stdenv.isDarwin {
    xdg.configFile."iterm2/com.googlecode.iterm2.plist".source =
      ../../resources/com.googlecode.iterm2.plist;
  };
}
