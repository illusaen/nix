{
  fleet.users.wendy = {
    identity = {
      displayName = "Wendy Chen";
      accountName = "illusaen";
      email = "jaewchen@gmail.com";
    };
    system.uid = 1000;
    groups = ["system-access" "kvm"];
  };

  flake.modules.generic.wendy = {
    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.wendy = {
      isNormalUser = true;
      extraGroups = ["wheel" "networkmanager"]; # Enable ‘sudo’ for the user.
      password = "arst";
    };
  };
}
