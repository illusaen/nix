{
  lib,
  config,
  ...
}: let
  inherit (lib) mkOption types nameValuePair;
  mapListToAttrsWith = attrs: value: attrs |> map (v: nameValuePair v value) |> builtins.listToAttrs;
  mkStrOption = default:
    mkOption {
      type = types.str;
      inherit default;
    };
in {
  config.flake.modules.nixos.fonts = {
    fonts.fontconfig.defaultFonts = rec {
      monospace = [config.fleet.fonts.mono "Maple Mono NF CN"];
      serif = sansSerif;
      sansSerif = [config.fleet.fonts.sans];
    };
  };

  config.flake.modules.generic.fonts = {pkgs, ...}: {
    config.fonts.packages = with pkgs; [
      font-awesome
      maple-mono.NF-CN-unhinted
      inter
      monaspace
      noto-fonts-color-emoji
      material-symbols
    ];
  };

  options.fleet.fonts = mkOption {
    type = types.submodule {
      options = {
        sans = mkStrOption "Inter";
        mono = mkStrOption "Monaspace Neon NF";
        emoji = mkStrOption "Noto Color Emoji";
        icon = mkStrOption "Material Symbols Outlined";
        sizes = mkOption {
          type = types.submodule {
            options = mapListToAttrsWith ["terminal" "applications" "desktop"] (mkOption {type = types.int;});
          };
          default = {
            terminal = 12;
            applications = 12;
            desktop = 13;
          };
        };
      };
    };
  };
}
