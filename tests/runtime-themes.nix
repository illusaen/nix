{
  api,
  lib,
  pkgs,
}: let
  odinSystemPackages = api.nixosConfigurations.odin.config.environment.systemPackages;
  packageNamed = name:
    lib.findFirst
    (package: (package.pname or package.name or "") == name)
    (throw "Odin system package '${name}' was not found")
    odinSystemPackages;
  themeApply = packageNamed "theme-apply";
  themeProfiles = packageNamed "nix-theme-profiles";
  profileChecks = lib.concatMapStringsSep "\n" (
    name: ''
      test -f ${themeProfiles}/${lib.escapeShellArg name}/niri-colors.kdl
      if grep -q '@base' ${themeProfiles}/${lib.escapeShellArg name}/niri-colors.kdl; then
        echo "unresolved Niri color placeholder in theme profile: ${name}" >&2
        exit 1
      fi
    ''
  ) (builtins.attrNames api.fleet.themes.profiles);
in
  pkgs.runCommand "runtime-theme-checks" {
    nativeBuildInputs = [pkgs.gnugrep themeApply];
  } ''
    ${profileChecks}

    export HOME="$TMPDIR/home"
    export XDG_STATE_HOME="$TMPDIR/state"
    export NIX_THEME_PROFILE_DIR="$TMPDIR/profiles"
    profile="$NIX_THEME_PROFILE_DIR/test"

    mkdir -p "$HOME" "$profile/gtk-3.0" "$profile/gtk-4.0" "$profile/qt5ct" "$profile/qt6ct"
    printf '%s\n' \
      'COLOR_SCHEME=default' \
      'GTK_THEME=test' \
      'ICON_THEME=test' \
      'CURSOR_THEME=test' \
      'CURSOR_SIZE=24' \
      > "$profile/env"
    printf '%s\n' 'test-niri-colors' > "$profile/niri-colors.kdl"
    touch "$profile/gtk-3.0/settings.ini" "$profile/qt5ct/qt5ct.conf" "$profile/qt6ct/qt6ct.conf"

    theme-apply test

    test "$(readlink "$XDG_STATE_HOME/nix-theme/current")" = "$profile"
    test "$(readlink "$XDG_STATE_HOME/nix-theme/niri-colors.kdl")" = "$XDG_STATE_HOME/nix-theme/current/niri-colors.kdl"
    test "$(cat "$XDG_STATE_HOME/nix-theme/niri-colors.kdl")" = 'test-niri-colors'
    touch $out
  ''
