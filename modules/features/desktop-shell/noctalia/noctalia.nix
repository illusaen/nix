{inputs, ...}: {
  flake-file.inputs.noctalia = {
    url = "github:noctalia-dev/noctalia/main";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  flake.modules.nixos.noctalia = {pkgs, ...}: {
    imports = [inputs.noctalia.nixosModules.default];
    programs.noctalia = {
      enable = true;
      package = pkgs.local.noctalia-wrapped;
      systemd.enable = true;
    };
  };

  flake.fleetWrappers.noctalia-wrapped = {
    wlib,
    lib,
    pkgs,
    config,
    fleet,
    ...
  }: let
    desktopHosts =
      fleet.hosts
      |> builtins.attrValues
      |> builtins.filter (host: host.tags.role or null == "desktop");
    desktopHost = builtins.head desktopHosts;
  in {
    imports = [wlib.modules.default];
    package = pkgs.noctalia;

    env.NOCTALIA_CONFIG_DIR = dirOf config.constructFiles.generatedConfig.path;
    constructFiles.generatedConfig = {
      builder = let
        file = pkgs.replaceVars ./noctalia-config.toml.template {
          mono = fleet.fonts.mono.name;
          sans = fleet.fonts.sans.name;
          inherit (desktopHost.moduleSettings.monitors) main secondary;
          image = fleet.wallpaper.image;
          imageDirectory = fleet.wallpaper.directory;
          location = fleet.timeZone |> lib.splitString "/" |> lib.last;
        };
      in ''
        ln -s ${lib.escapeShellArg file} "$2"
      '';
      relPath = "noctalia-config.toml";
    };
  };
}
