{inputs, ...}: {
  flake-file.inputs.hjem = {
    url = "github:feel-co/hjem";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  flake.modules.generic.hjem = {user, ...}: {
    hjem.users.${user.name}.enable = true;
  };

  flake.modules.nixos.hjem.imports = [inputs.hjem.nixosModules.default];
  flake.modules.darwin.hjem.imports = [inputs.hjem.darwinModules.default];
}
