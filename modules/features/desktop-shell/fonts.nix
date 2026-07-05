{
  lib,
  helpers,
  ...
}: {
  flake.modules.nixos.fonts = {fleet, ...}: let
    inherit (fleet.fonts) mono sans;
  in {
    fonts.fontconfig.defaultFonts = rec {
      monospace = [mono.name "Maple Mono NF CN"];
      serif = sansSerif;
      sansSerif = [sans.name];
    };
    fonts.fontconfig.aliases = let
      inherit (helpers) removeAttrs';
    in
      fleet.fonts |> removeAttrs' ["sizes"] |> lib.mapAttrs' (_name: value: lib.nameValuePair value.name {default = ["Font Awesome 7 Free"];});
  };

  flake.modules.generic.fonts = {pkgs, ...}: {
    fonts.packages = with pkgs; [
      font-awesome
      maple-mono.NF-CN-unhinted
      inter
      monaspace
      noto-fonts-color-emoji
      material-symbols
    ];
  };
}
