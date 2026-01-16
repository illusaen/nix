{
  lib,
  pkgs,
  ...
}:

pkgs.stdenvNoCC.mkDerivation rec {
  pname = "zmk-studio";
  version = "0.3.1";

  src = pkgs.fetchurl {
    url = "https://github.com/zmkfirmware/zmk-studio/releases/download/v${version}/ZMK.Studio_${version}_universal.dmg";
    hash = "sha256-zzl/mC9WSSVQBcp3clwSNqEWgOSzVm1v8R5GE5ozSJ4=";
  };

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
    license = licenses.asl20;
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
    ];
  };
}
