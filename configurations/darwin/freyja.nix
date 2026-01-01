{ pkgs, vars, ... }:
let
  inherit (vars) name fullName;
in
{
  networking.hostName = "freyja";
  system.primaryUser = name;
  users.users.${name} = {
    description = fullName;
    shell = pkgs.fish;
    home = "/Users/${name}";
  };

  system.stateVersion = 6;
}
