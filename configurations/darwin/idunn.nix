{ pkgs, vars, ... }:
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

  system.stateVersion = 6;
}
