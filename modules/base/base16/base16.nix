{
  inputs,
  lib,
  ...
}: {
  flake-file.inputs.base16.url = "github:SenchoPens/base16.nix";

  flake.modules.nixos.base16 = {
    imports = [inputs.base16.nixosModule];

    options.colorScheme = lib.mkOption {
      type = lib.types.enum ["dark" "light"];
    };

    config = {
      scheme = ./tokyo-night-moon.yaml;
      colorScheme = "dark";
    };
  };
}
