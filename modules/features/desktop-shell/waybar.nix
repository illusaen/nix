{
  rootPath,
  helpers,
  config,
  ...
}: {
  flake.modules.nixos.waybar = {pkgs, ...}: {
    environment.systemPackages = [pkgs.local.waybar];
    systemd.packages = [pkgs.local.waybar];
    systemd.user.services.waybar = {
      wantedBy = ["graphical-session.target"];
      after = ["swaync.service"];
    };
  };

  flake.wrappers.waybar = {pkgs, ...}: let
    inherit (helpers) removeAttrs';
    fonts = config.fleet.fonts |> removeAttrs' ["sizes" "emoji"] |> builtins.mapAttrs (_name: value: value.name);
    size = config.fleet.fonts.sizes.applications;
    monitors = config.fleet.monitors.conn;
    scheme = (config.fleet.base16.scheme pkgs).withHashtag;
  in {
    imports = [(rootPath + /wrappers/waybar/module.nix)];
    font = fonts // {inherit size;};
    inherit monitors scheme;
  };
}
