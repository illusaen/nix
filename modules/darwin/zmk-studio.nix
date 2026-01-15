{
  lib,
  pkgs,
  helpers,
  config,
  ...
}:
let
  studio = pkgs.stdenvNoCC.mkDerivation (finalAttrs: rec {
    pname = "zmk-studio";
    version = "0.3.1";

    githubUrl = "https://github.com/zmkfirmware/zmk-studio/releases/download/v${finalAttrs.version}";
    fileName = "ZMK.Studio_${finalAttrs.version}_universal.dmg";
    src = (
      pkgs.fetchurl {
        url = "${githubUrl}/${fileName}";
        hash = "sha256-zzl/mC9WSSVQBcp3clwSNqEWgOSzVm1v8R5GE5ozSJ4=";
      }
    );

    packages = [ pkgs.undmg ];
    nativeBuildInputs = packages;

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall

      mkdir -p $out/Applications
      cp -r *.app $out/Applications

      runHook postInstall
    '';

    meta = with lib; {
      description = "ZMK Studio";
      longDescription = ''
        Initial work on the ZMK Studio UI.
      '';
      homepage = "https://github.com/zmkfirmware/zmk-studio";
      # license = licenses.apache2;
      # maintainers = with maintainers; [ eelco ];
      platforms = [
        "aarch64-darwin"
        "x86_64-darwin"
      ];
    };
  });

  cfg = config.modules.zmk-studio;
in
{
  options.modules.zmk-studio.enable = helpers.mkTrueOption "Install ZMK Studio";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ studio ];
  };
}
