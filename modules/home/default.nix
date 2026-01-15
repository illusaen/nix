{
  lib,
  vars,
  pkgs,
  ...
}:
{
  home = {
    username = lib.mkDefault vars.name;
    homeDirectory = if pkgs.stdenv.isDarwin then "/Users/${vars.name}" else "/home/${vars.name}";

    # Do NOT change this value. stateVersion determines compatibility for stateful data,
    # not which home-manager version you're running. Only change after reading release notes.
    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    stateVersion = lib.mkDefault "25.11";
  };
}
