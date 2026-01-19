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
      "raspberry-pi-imager"
      "mac-mouse-fix"
      "autodesk-fusion"
      "openscad"
    ];
    masApps = {
      "Cyberduck" = 409222199;
    };
  };

  environment.systemPackages = with pkgs; [
    zstd
  ];

  system.stateVersion = 6;
}
