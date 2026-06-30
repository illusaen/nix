{
  flake.modules.generic.one-password = {pkgs, ...}: {
    programs._1password.enable = true;
    programs._1password-gui = {
      enable = true;
      package = pkgs._1password-gui-beta;
    };
  };

  flake.modules.nixos.one-password = {
    config,
    user,
    ...
  }: {
    programs._1password-gui.polkitPolicyOwners = [user.name];
    systemdAutostart = [
      {
        name = "one-password";
        inherit (config.programs._1password-gui) package;
      }
    ];
    persistUser.directories = [".config/1Password"];
  };
}
