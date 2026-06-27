{config, ...}: {
  flake.modules.generic.programs.imports = with config.flake.modules.generic; [zed];
}
