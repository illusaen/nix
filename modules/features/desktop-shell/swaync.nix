{
  rootPath,
  config,
  ...
}: {
  flake.modules.nixos.desktop-shell = {pkgs, ...}: {
    environment.systemPackages = [pkgs.local.swaync];
    systemd.packages = [pkgs.local.swaync];
    systemd.user.services.swaync.wantedBy = ["graphical-session.target"];
  };
  flake.wrappers.swaync = {pkgs, ...}: {
    imports = [(rootPath + /wrappers/swaync/module.nix)];

    font = config.fleet.fonts.sans.name;
    scheme = config.fleet.base16.scheme pkgs;
  };
}
