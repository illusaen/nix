{
  flake.modules.nixos.misc-scripts = {pkgs, ...}: {
    environment.systemPackages = [pkgs.local.misc-scripts];
  };
}
