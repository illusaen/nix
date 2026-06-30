{
  flake.modules.nixos.swayosd = {pkgs, ...}: {
    environment.systemPackages = [pkgs.local.swayosd];
    systemd.packages = [pkgs.local.swayosd];
    systemd.services.swayosd-libinput-backend.wantedBy = ["graphical.target"];
  };

  flake.wrappers.swayosd = {
    wlib,
    pkgs,
    ...
  }: {
    imports = [wlib.modules.default];
    package = pkgs.swayosd;
    filesToPatch = ["lib/systemd/system/swayosd-libinput-backend.service"];
  };
}
