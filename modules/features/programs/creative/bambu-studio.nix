{
  flake.modules.nixos.bambu-studio = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [bambu-studio];
  };

  flake.modules.darwin.bambu-studio.homebrew.casks = ["bambu-studio"];
}
