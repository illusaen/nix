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
      description = "Mutable Noctalia config home for fast UI iteration. Noctalia reads config.toml from the noctalia subdirectory.";
    };
  };

  # This is needed because Noctalia option declarations are under `generic`
  # scope; settings options only load for names that have a concrete module.
  flake.modules.generic.noctalia = {};

  flake.modules.nixos.noctalia = {
    fleet,
    host,
    moduleSettings,
    pkgs,
    self,
    ...
  }: let
    package = self.wrappers.noctalia-wrapped.wrap {
      inherit pkgs;
      _module.args = {
        inherit fleet moduleSettings;
        inherit (host) monitors;
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

    nix.settings = {
      extra-substituters = ["https://noctalia.cachix.org"];
      extra-trusted-public-keys = [
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      ];
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
    moduleSettings = config._module.args.moduleSettings or {};
    hasFleet = fleet != null;
    devConfigDir = moduleSettings.noctalia.devConfigDir or null;
  in {
    imports = [wlib.modules.default];
    package = pkgs.noctalia;

    env.NOCTALIA_CONFIG_HOME = lib.mkIf hasFleet (
      if devConfigDir != null
      then devConfigDir
      else {
        data = "\${NIX_THEME_STATE_DIR:-\${XDG_STATE_HOME:-$HOME/.local/state}/nix-theme}/current";
        esc-fn = wlib.escapeShellArgWithEnv;
      }
    );
  };
}
