{
  pkgs,
  vars,
  config,
  ...
}:
let
  inherit (vars) name fullName;
in
{
  networking.hostName = "idunn";
  system.primaryUser = name;
  users.users.${name} = {
    description = fullName;
    shell = pkgs.fish;
    home = "/Users/${name}";
  };

  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
    };
  };

  config.modules.idunn.enable = true;

  system.stateVersion = 6;
}
