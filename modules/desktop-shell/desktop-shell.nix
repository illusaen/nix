{config, ...}: {
  flake.modules.nixos.desktop-shell = {
    imports = with config.flake.modules.nixos; [
      niri
    ];
  };
}
