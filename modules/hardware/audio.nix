{
  flake.modules.nixos.audio = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [pavucontrol];
    services = {
      playerctld.enable = true;
      pipewire.alsa.support32Bit = true;
    };
    security.rtkit.enable = true;
  };
}
