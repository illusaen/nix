{inputs, ...}: {
  flake-file.inputs.noctalia = {
    url = "github:noctalia-dev/noctalia/main";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  flake.modules.nixos.noctalia = {
    fleet,
    host,
    pkgs,
    self,
    ...
  }: let
    package = self.wrappers.noctalia-wrapped.wrap {
      inherit pkgs;
      _module.args = {
        inherit fleet;
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
    hasFleet = fleet != null;
  in {
    imports = [wlib.modules.default];
    package = pkgs.noctalia;

    env.NOCTALIA_CONFIG_HOME = lib.mkIf hasFleet {
      data = "\${NIX_THEME_STATE_DIR:-\${XDG_STATE_HOME:-$HOME/.local/state}/nix-theme}/current";
      esc-fn = wlib.escapeShellArgWithEnv;
    };
  };
}
