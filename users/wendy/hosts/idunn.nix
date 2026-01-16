{
  config,
  ...
}:
{
  imports = [ ../default.nix ];
  home.homeDirectory = "/Users/${config.home.username}";
}
