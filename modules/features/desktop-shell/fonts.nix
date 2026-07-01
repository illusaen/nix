{
  lib,
  helpers,
  ...
}: let
  inherit (lib) mkOption types nameValuePair;
  mapListToAttrsWith = attrs: value: attrs |> map (v: nameValuePair v value) |> builtins.listToAttrs;
in {
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

  fleet.fonts = {
    sans = {
      name = "Inter";
      packageName = "inter";
    };
    mono = {
      name = "Monaspace Neon NF";
      packageName = "monaspace";
    };
    emoji = {
      name = "Noto Color Emoji";
      packageName = "noto-fonts-color-emoji";
    };
    icon = {
      name = "Material Symbols Outlined";
      packageName = "material-symbols";
    };
    sizes = {
      terminal = 12;
      applications = 12;
      desktop = 13;
    };
  };

  schema.fleet.options.fonts = mkOption {
    type = types.submodule {
      options = let
        inherit (helpers) mkThemeOption;
      in {
        sans = mkThemeOption {};
        mono = mkThemeOption {};
        emoji = mkThemeOption {};
        icon = mkThemeOption {};
        sizes = mkOption {
          type = types.submodule {
            options = mapListToAttrsWith ["terminal" "applications" "desktop"] (mkOption {type = types.int;});
          };
        };
      };
    };
  };
}
