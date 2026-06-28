{rootPath, ...}: {
  flake.modules.nixos.desktop-shell = {pkgs, ...}: {
    environment.systemPackages = [pkgs.local.swayidle];
    systemd.packages = [pkgs.local.swayidle];
    systemd.user.services.swayidle.wantedBy = ["graphical-session.target"];
  };
  flake.wrappers.swayidle = rootPath + /wrappers/swayidle.nix;
}
