{lib, ...}: let
  mkProfiles = pkgs: let
    extensions = import ./_extensions.nix {inherit pkgs;};
  in
    lib.pipe extensions [
      (lib.mapAttrs (
        n: v: {
          location = n;
          icon = "globe";
          useDefaultFlags = {
            settings = true;
            keybindings = true;
            tasks = true;
            snippets = true;
            mcp = true;
          };
          extensions = v;
        }
      ))
    ];

  mkUserDir = pkgs:
    if pkgs.stdenv.isDarwin
    then "Library/Application Support/Code/User"
    else ".config/Code/User";

  mkSyncProfilesScript = pkgs: let
    profiles = removeAttrs (mkProfiles pkgs) ["default"];
    desiredProfilesJson = builtins.toJSON (
      lib.mapAttrsToList (n: v: {
        name = n;
        inherit (v) location useDefaultFlags icon;
      })
      profiles
    );
  in
    pkgs.writeShellScriptBin "sync-vscode-profiles" ''
      PATH=${lib.makeBinPath [pkgs.jq]}''${PATH:+:}$PATH
      file="$HOME/${mkUserDir pkgs}/globalStorage/storage.json"
      desired_profiles=${lib.escapeShellArg desiredProfilesJson}

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
in {
  flake.modules.generic.vscode = {pkgs, ...}: {
    environment.systemPackages = [
      pkgs.vscode
      (mkSyncProfilesScript pkgs)
    ];
  };

  flake.modules.nixos.vscode = {
    pkgs,
    lib,
    fleet,
    user,
    ...
  }: let
    inherit (fleet) fonts;
    extensionJsonFile = name: text:
      pkgs.writeTextFile {
        inherit text;
        name = "extensions-json-${name}";
        destination = "/share/vscode/extensions/extensions.json";
      };

    userDir = mkUserDir pkgs;
    syncProfilesScript = mkSyncProfilesScript pkgs;

    profiles = mkProfiles pkgs;
    allProfilesExceptDefault = removeAttrs profiles ["default"];

    generatedFiles = lib.flatten [
      {
        ".vscode/argv.json" = {
          generator = lib.generators.toJSON {};
          value = {
            enable-crash-reporter = true;
            crash-reporter-id = "d17b2c57-3182-4ec0-a09f-c8abd1812a80";
            password-store = "gnome-libsecret";
          };
        };
      }

      {
        "${userDir}/settings.json".source = pkgs.replaceVars ./settings.json.template {
          fontSize = builtins.floor (fonts.sizes.terminal * 1.1);
          monoFontName = "${fonts.mono.name},Maple Mono NF CN";
          serifFontName = "Monaspace Xenon Frozen";
          sansFontName = fonts.sans.name;
          zoomLevel = 0;
        };
      }

      (lib.mapAttrs' (
          n: v:
            lib.nameValuePair "${userDir}/profiles/${n}/extensions.json" {
              source = "${
                extensionJsonFile n (
                  pkgs.vscode-utils.toExtensionJson (v.extensions ++ profiles.default.extensions)
                )
              }/share/vscode/extensions/extensions.json";
            }
        )
        allProfilesExceptDefault)

      {
        ".vscode/extensions" = {
          source = let
            combinedExtensionsDrv = pkgs.buildEnv {
              name = "vscode-extensions";
              paths =
                (lib.pipe profiles [
                  (lib.collect builtins.isList)
                  lib.flatten
                ])
                ++ [
                  (extensionJsonFile "default" (pkgs.vscode-utils.toExtensionJson profiles.default.extensions))
                ];
            };
          in "${combinedExtensionsDrv}/share/vscode/extensions";
        };
      }
    ];
  in {
    persistUser.directories = [
      ".config/Code/User/globalStorage"
    ];

    system.userActivationScripts.syncVscodeProfiles = ''
      echo "Syncing vscode profiles."
      ${lib.getExe syncProfilesScript}
    '';

    hjem.users.${user.name}.files = lib.mkMerge generatedFiles;
  };
}
