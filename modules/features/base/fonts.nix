{
  lib,
  config,
  helpers,
  ...
}: let
  inherit (lib) mkOption types nameValuePair;
  mapListToAttrsWith = attrs: value: attrs |> map (v: nameValuePair v value) |> builtins.listToAttrs;
in {
  config.flake.modules.nixos.fonts = let
    inherit (config.fleet.fonts) mono sans;
  in {
    fonts.fontconfig.defaultFonts = rec {
      monospace = [mono.name "Maple Mono NF CN"];
      serif = sansSerif;
      sansSerif = [sans.name];
    };
    fonts.fontconfig.aliases = let
      inherit (helpers) removeAttrs';
    in
      config.fleet.fonts |> removeAttrs' ["sizes"] |> lib.mapAttrs' (_name: value: lib.nameValuePair value.name {default = ["Font Awesome 7 Free"];});
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

  config.fleet.fonts = {
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

  options.fleet.fonts = mkOption {
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
