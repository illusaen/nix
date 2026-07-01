{inputs, ...}: {
  flake-file.inputs.noctalia = {
    url = "github:noctalia-dev/noctalia/main";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  flake.modules.nixos.noctalia = {
    fleet,
    moduleSettings,
    pkgs,
    ...
  }: let
    package = pkgs.local.noctalia-wrapped.passthru.wrap {
      _module.args = {
        inherit fleet moduleSettings;
      };
    };
  in {
    imports = [inputs.noctalia.nixosModules.default];
    programs.noctalia = {
      enable = true;
      inherit package;
      systemd.enable = true;
    };
  };

  flake.wrappers.noctalia-wrapped = {
    config,
    lib,
    wlib,
    pkgs,
    ...
  }: let
    fleet = config._module.args.fleet or null;
    moduleSettings = config._module.args.moduleSettings or null;
    hasHostSettings = fleet != null && moduleSettings != null && moduleSettings ? monitors;
  in {
    imports = [wlib.modules.default];
    package = pkgs.noctalia;

    env.NOCTALIA_CONFIG_DIR = lib.mkIf hasHostSettings (dirOf config.constructFiles.generatedConfig.path);
    constructFiles.generatedConfig = lib.mkIf hasHostSettings {
      builder = let
        file = pkgs.replaceVars ./noctalia-config.toml.template {
          mono = fleet.fonts.mono.name;
          sans = fleet.fonts.sans.name;
          inherit (moduleSettings.monitors) main secondary;
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
