top: {
  flake.modules.generic.one-password = {pkgs, ...}: {
    programs._1password.enable = true;
    programs._1password-gui = {
      enable = true;
      package = pkgs._1password-gui-beta;
    };
  };

  flake.modules.nixos.one-password = {
    lib,
    config,
    ...
  }: {
    programs._1password-gui.polkitPolicyOwners =
      lib.mapAttrsToList (
        _: value: value.userName
      )
      top.config.fleet.users;

    systemdAutostart = [config.programs._1password-gui.package];
    persistUser.directories = [".config/1Password"];
  };
}
