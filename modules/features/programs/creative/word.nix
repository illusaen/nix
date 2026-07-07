{
  flake.modules.nixos.word = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [onlyoffice-desktopeditors];
  };
}
