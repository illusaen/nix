_: {
  imports = [];

  modules.nixos = {
    lib,
    pkgs,
    ...
  }: let
    themeStateDir = "\${NIX_THEME_STATE_DIR:-\${XDG_STATE_HOME:-$HOME/.local/state}/nix-theme}";
    optionalPackage = name:
      lib.optional (pkgs ? ${name}) pkgs.${name};
    wrappedZathura =
      if pkgs ? zathura
      then
        pkgs.symlinkJoin {
          name = "zathura-wrapped";
          paths = [pkgs.zathura];
          nativeBuildInputs = [pkgs.makeWrapper];
          postBuild = ''
            rm -f "$out/bin/zathura"
            makeWrapper ${pkgs.zathura}/bin/zathura "$out/bin/zathura" \
              --add-flags "--config-dir ${themeStateDir}/current/zathura"
          '';
        }
      else null;
    wrappedZed =
      if pkgs ? zed-editor
      then
        pkgs.symlinkJoin {
          name = "zed-editor-wrapped";
          paths = [pkgs.zed-editor];
          nativeBuildInputs = [pkgs.makeWrapper];
          postBuild = ''
            rm -f "$out/bin/zeditor"
            makeWrapper ${pkgs.zed-editor}/bin/zeditor "$out/bin/zeditor" \
              --run 'zed_data_dir="''${XDG_DATA_HOME:-$HOME/.local/share}/zed-wrapped"' \
              --run 'theme_dir="${themeStateDir}/current/zed"' \
              --run 'mkdir -p "$zed_data_dir/config/themes"' \
              --run 'rm -f "$zed_data_dir/config/settings.json" "$zed_data_dir/config/themes/base24-theme.json"' \
              --run 'ln -sfn "$theme_dir/settings.json" "$zed_data_dir/config/settings.json"' \
              --run 'ln -sfn "$theme_dir/themes/base24-theme.json" "$zed_data_dir/config/themes/base24-theme.json"' \
              --add-flags '--user-data-dir "''${XDG_DATA_HOME:-$HOME/.local/share}/zed-wrapped"'
          '';
        }
      else null;
  in {
    environment.systemPackages =
      [pkgs.meld]
      ++ optionalPackage "codex"
      ++ optionalPackage "codex-acp"
      ++ lib.optional (wrappedZathura != null) wrappedZathura
      ++ lib.optional (wrappedZed != null) wrappedZed;

    xdg.mime.defaultApplications = let
      reader = "org.pwmt.zathura.desktop";
    in {
      "application/pdf" = reader;
      "application/epub+zip" = reader;
      "application/postscript" = reader;
    };

    persistUser.directories = [
      ".codex"
      ".config/zed"
      ".local/share/zed"
    ];
  };

  modules.darwin = _: {
    homebrew.casks = ["codex-app"];
  };
}
