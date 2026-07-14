{
  imports = [];

  modules.nixos = {
    fleet,
    lib,
    pkgs,
    user,
    ...
  }: let
    userName = user.name or "wendy";
    themeStateDir = "\${NIX_THEME_STATE_DIR:-\${XDG_STATE_HOME:-$HOME/.local/state}/nix-theme}";
    extensions = import ../../modules/features/programs/dev/vscode/_extensions.nix {inherit pkgs;};
    vscodeProfiles =
      lib.mapAttrs (_name: extensionList: {
        location = _name;
        icon = "globe";
        useDefaultFlags = {
          settings = true;
          keybindings = true;
          tasks = true;
          snippets = true;
          mcp = true;
        };
        extensions = extensionList;
      })
      extensions;
    vscodeUserDir = ".config/Code/User";
    vscodeExtensionJsonFile = name: text:
      pkgs.writeTextFile {
        inherit text;
        name = "extensions-json-${name}";
        destination = "/share/vscode/extensions/extensions.json";
      };
    vscodeProfilesExceptDefault = removeAttrs vscodeProfiles ["default"];
    vscodeDesiredProfilesJson = builtins.toJSON (
      lib.mapAttrsToList (name: profile: {
        inherit name;
        inherit (profile) location useDefaultFlags icon;
      })
      vscodeProfilesExceptDefault
    );
    syncVscodeProfiles = pkgs.writeShellScriptBin "sync-vscode-profiles" ''
      PATH=${lib.makeBinPath [pkgs.jq]}''${PATH:+:}$PATH
      file="$HOME/${vscodeUserDir}/globalStorage/storage.json"
      desired_profiles=${lib.escapeShellArg vscodeDesiredProfilesJson}

      if [ ! -f "$file" ]; then
        mkdir -p "$(dirname "$file")"
        echo "{}" > "$file"
      fi

      jq --argjson desired_profiles "$desired_profiles" '
        .userDataProfiles = (
          (.userDataProfiles // []) as $current
          | reduce $desired_profiles[] as $profile ($current;
              if any(.[]; .name == $profile.name) then
                map(
                  if .name == $profile.name then
                    . + {
                      location: $profile.location,
                      useDefaultFlags: $profile.useDefaultFlags,
                      icon: $profile.icon
                    }
                  else
                    .
                  end
                )
              else
                . + [$profile]
              end
            )
        )
      ' "$file" > "$file.tmp"

      mv "$file.tmp" "$file"
    '';
    vscodeExtensions = pkgs.buildEnv {
      name = "vscode-extensions";
      paths =
        (lib.flatten (map (profile: profile.extensions) (builtins.attrValues vscodeProfiles)))
        ++ [
          (vscodeExtensionJsonFile "default" (pkgs.vscode-utils.toExtensionJson vscodeProfiles.default.extensions))
        ];
    };
    vscodeGeneratedFiles =
      {
        ".vscode/argv.json" = {
          generator = lib.generators.toJSON {};
          value = {
            enable-crash-reporter = true;
            crash-reporter-id = "d17b2c57-3182-4ec0-a09f-c8abd1812a80";
            password-store = "gnome-libsecret";
          };
        };
        "${vscodeUserDir}/settings.json".source = pkgs.replaceVars ../../modules/features/programs/dev/vscode/settings.json.template {
          fontSize = builtins.floor (fleet.fonts.sizes.terminal * 1.1);
          monoFontName = "${fleet.fonts.mono.name},Maple Mono NF CN";
          serifFontName = "Monaspace Xenon Frozen";
          sansFontName = fleet.fonts.sans.name;
          zoomLevel = 1;
        };
        ".vscode/extensions".source = "${vscodeExtensions}/share/vscode/extensions";
      }
      // lib.mapAttrs' (
        name: profile:
          lib.nameValuePair "${vscodeUserDir}/profiles/${name}/extensions.json" {
            source = "${
              vscodeExtensionJsonFile name (
                pkgs.vscode-utils.toExtensionJson (profile.extensions ++ vscodeProfiles.default.extensions)
              )
            }/share/vscode/extensions/extensions.json";
          }
      )
      vscodeProfilesExceptDefault;
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
      ++ optionalPackage "vscode"
      ++ [syncVscodeProfiles]
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
      ".config/Code/User/globalStorage"
      ".config/zed"
      ".local/share/zed"
    ];

    system.userActivationScripts.syncVscodeProfiles = ''
      echo "Syncing vscode profiles."
      ${lib.getExe syncVscodeProfiles}
    '';

    hjem.users.${userName}.files = vscodeGeneratedFiles;
  };

  modules.darwin = _: {
    homebrew.casks = ["codex-app"];
  };
}
