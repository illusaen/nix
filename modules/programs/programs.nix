{config, ...}: {
  flake.modules.generic.programs.imports = with config.flake.modules.generic; [one-password zed];
  flake.modules.nixos.programs.imports = with config.flake.modules.nixos; [firefox one-password autostart];
  flake.modules.darwin.programs.imports = with config.flake.modules.darwin; [firefox];
}
