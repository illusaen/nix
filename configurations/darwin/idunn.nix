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
    masApps = {
      "Tailscale" = 1475387142;
    };
  };

  system = {
    keyboard.remapCapsLockToControl = true;
    defaults = {
      NSGlobalDomain."com.apple.mouse.tapBehavior" = 1;
      dock.tilesize = 48;
      dock.largesize = 64;
    };
  };
  security.pam.services.sudo_local.touchIdAuth = true;

  system.stateVersion = 6;
}
