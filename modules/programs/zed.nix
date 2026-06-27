{
  config,
  rootPath,
  ...
}: {
  flake.modules.generic.zed = {pkgs, ...}: {environment.systemPackages = [pkgs.local.zed];};

  flake.wrappers.zed = {pkgs, ...}: {
    imports = [(rootPath + /wrappers/zed/module.nix)];
    fonts = {
      inherit (config.fleet.fonts) sans mono icon;
      size = config.fleet.fonts.sizes.applications;
    };
    scheme = config.fleet.base16.scheme pkgs;
  };
}
