{rootPath, ...}: {
  flake.modules.nixos.swaync = {pkgs, ...}: {
    environment.systemPackages = [pkgs.local.swaync];
    systemd.packages = [pkgs.local.swaync];
    systemd.user.services.swaync.wantedBy = ["graphical-session.target"];
  };
  flake.fleetWrappers.swaync = {
    pkgs,
    fleet,
    ...
  }: {
    imports = [(rootPath + /wrappers/swaync/module.nix)];
    font = fleet.fonts.sans.name;
    fontSize = fleet.fonts.sizes.applications;
    scheme = fleet.base16.scheme pkgs;
  };
}
