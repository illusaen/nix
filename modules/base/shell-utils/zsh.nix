{
  flake.modules.generic.shell-utils = {pkgs, ...}: {environment.systemPackages = [(pkgs.local.zsh or pkgs.zsh)];};

  flake.modules.nixos.zsh = {pkgs, ...}: {
    users.defaultUserShell = pkgs.local.zsh or pkgs.zsh;
  };

  flake.modules.darwin.zsh = {
    pkgs,
    lib,
    config,
    ...
  }: {
    users.users = lib.mapAttrs (_user: {shell = pkgs.local.zsh or pkgs.zsh;}) config.users.users;
  };
}
