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

  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
    };
    casks = [
      "bambu-studio"
    ];
    masApps = {
      "Cyberduck" = 409222199;
    };
  };

  modules.freyja.enable = true;

  system.stateVersion = 6;
}
