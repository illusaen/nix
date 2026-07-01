{
  flake.modules.generic.meld = {pkgs, ...}: {environment.systemPackages = [pkgs.meld];};
}
