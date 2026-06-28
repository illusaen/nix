{
  flake.modules.nixos.desktop-shell = {pkgs, ...}: {
    environment.systemPackages = [pkgs.local.swayosd];
    systemd.packages = [pkgs.local.swayosd];
    systemd.services.swayosd-libinput-backend.wantedBy = ["graphical.target"];
  };

  flake.wrappers.swayosd = {
    wlib,
    pkgs,
    config,
    ...
  }: {
    imports = [wlib.modules.default];
    package = pkgs.swayosd;
    env.XDG_CONFIG_HOME = dirOf config.constructFiles.generatedTheme.path;
    filesToPatch = ["lib/systemd/system/swayosd-libinput-backend.service"];
  };
}
