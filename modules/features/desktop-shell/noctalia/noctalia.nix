{
  inputs,
  lib,
  ...
}: {
  flake-file.inputs.noctalia = {
    url = "github:noctalia-dev/noctalia/main";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  flake.moduleOptions.generic.noctalia = {
    devConfigDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Mutable Noctalia config directory for fast UI iteration.";
    };
  };

  # This is needed because Noctalia option declarations are under `generic`
  # scope; settings options only load for names that have a concrete module.
  flake.modules.generic.noctalia = {};

  flake.modules.nixos.noctalia = {
    fleet,
    moduleSettings,
    pkgs,
    self,
    ...
  }: let
    package = self.wrappers.noctalia-wrapped.wrap {
      inherit pkgs;
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

    nixpkgs.overlays = [inputs.noctalia.overlays.default];
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
    devConfigDir = moduleSettings.noctalia.devConfigDir or null;
  in {
    imports = [wlib.modules.default];
    package = pkgs.noctalia;

    env.NOCTALIA_CONFIG_DIR = lib.mkIf hasHostSettings (
      if devConfigDir != null
      then devConfigDir
      else "\${NIX_THEME_STATE_DIR:-\${XDG_STATE_HOME:-$HOME/.local/state}/nix-theme}/current/noctalia"
    );
    constructFiles.generatedConfig = lib.mkIf (hasHostSettings && devConfigDir != null) {
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
