{inputs, ...}: {
  flake-file.inputs.noctalia = {
    url = "github:noctalia-dev/noctalia/main";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  flake.modules.nixos.noctalia = {pkgs, ...}: {
    imports = [inputs.noctalia.nixosModules.default];
    nixpkgs.overlays = [inputs.noctalia.overlays.default];
    programs.noctalia = {
      enable = true;
      package = pkgs.noctalia;
      systemd.enable = true;
    };
  };
}
