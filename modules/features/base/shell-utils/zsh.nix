{self, ...}: {
  flake.modules.generic.shell-utils = {pkgs, ...}: {environment.systemPackages = [(pkgs.local.zsh or pkgs.zsh)];};

  flake.modules.nixos.zsh = {
    imports = [self.nixosModules.zsh];
    wrappers.zsh = {
      enable = true;
      asSystemDefault = true;
    };
  };

  flake.modules.darwin.zsh = {
    pkgs,
    lib,
    config,
    ...
  }: {
    users.users = lib.mapAttrs (_user: {shell = pkgs.local.zsh or pkgs.zsh;}) config.users.users;
  };

  flake.wrappers.zsh = {
    wlib,
    lib,
    pkgs,
    ...
  }: {
    imports = [wlib.wrapperModules.zsh];
    zshrc.content = ''
      eval "$(${lib.getExe pkgs.zoxide} init zsh --cmd n)"
      eval "$(${lib.getExe pkgs.local.starship} init zsh)"
    '';
  };
}
