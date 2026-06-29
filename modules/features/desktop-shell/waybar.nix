{
  rootPath,
  helpers,
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

  flake.fleetWrappers.waybar = {
    fleet,
    pkgs,
    ...
  }: let
    inherit (helpers) removeAttrs';
    fonts = fleet.fonts |> removeAttrs' ["sizes" "emoji"] |> builtins.mapAttrs (_name: value: value.name);
    size = fleet.fonts.sizes.applications;
    monitors = fleet.monitors.conn;
    scheme = (fleet.base16.scheme pkgs).withHashtag;
  in {
    imports = [(rootPath + /wrappers/waybar/module.nix)];
    font = fonts // {inherit size;};
    inherit monitors scheme;
  };
}
