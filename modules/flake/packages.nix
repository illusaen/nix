{
  inputs,
  rootPath,
  withSystem,
  self,
  ...
}: {
  flake-file.inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    pkgs-by-name-for-flake-parts.url = "github:drupol/pkgs-by-name-for-flake-parts";
  };

  imports = [inputs.pkgs-by-name-for-flake-parts.flakeModule];

  flake = {
    overlays.default = _final: prev:
      withSystem prev.stdenv.hostPlatform.system (
        {config, ...}: {
          local = config.packages;
        }
      );
  };

  perSystem = {
    system,
    config,
    ...
  }: let
    pkgs = import inputs.nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
      overlays = [(_final: _prev: {local = config.packages;})];
    };
  in {
    _module.args.pkgs = pkgs;
    pkgsDirectory = rootPath + /packages;

    # Placing long building packages into packages for gh workflow to build and cache
    packages = {
      inherit (pkgs) bambu-studio;
      llama-cpp = pkgs.llama-cpp.override {cudaSupport = true;};
    };
  };

  flake.modules.generic.package-overlay = {
    nixpkgs.overlays = [self.overlays.default];
  };
}
