{
  modules.generic = {pkgs, ...}: {
    programs = {
      _1password.enable = true;
      _1password-gui = {
        enable = true;
        package = pkgs._1password-gui-beta;
      };
    };
  };

  modules.nixos = {
    pkgs,
    user,
    ...
  }: {
    programs._1password-gui.polkitPolicyOwners = [user.name];

    persistUser.directories = [
      ".config/1Password"
    ];

    systemdAutostart = [
      {
        name = "one-password";
        package = pkgs._1password-gui-beta;
      }
    ];
  };
}
