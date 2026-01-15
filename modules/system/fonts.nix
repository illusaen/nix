{
  lib,
  pkgs,
  vars,
  ...
}:
let
  feather = pkgs.stdenvNoCC.mkDerivation {
    name = "feather";
    src = pkgs.fetchFromGitHub {
      owner = "AT-UI";
      repo = "feather-font";
      rev = "2ac71612ee85b3d1e9e1248cec0a777234315253";
      sha256 = "sha256-W4CHvOEOYkhBtwfphuDIosQSOgEKcs+It9WPb2Au0jo=";
    };
    phases = [
      "installPhase"
    ];
    installPhase = ''
      mkdir -p $out/share/fonts/truetype
      cp -r $src/src/fonts/*.ttf $out/share/fonts/truetype/
    '';
  };

  sf-pro = pkgs.stdenvNoCC.mkDerivation {
    name = "sf-pro";
    src = pkgs.fetchurl {
      url = "https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg";
      hash = "sha256-u7cLbIRELSNFUa2OW/ZAgIu6vbmK/8kXXqU97xphA+0=";
    };
    buildInputs = with pkgs; [
      undmg
      p7zip
    ];
    phases = [
      "unpackPhase"
      "installPhase"
    ];
    unpackPhase = ''
      undmg $src
      7z x "SF Pro Fonts.pkg"
      7z x "Payload~"
    '';
    installPhase = ''
      mkdir -p $out/share/fonts/{opentype,truetype}
      find -name \*.otf -exec mv {} $out/share/fonts/opentype/ \;
      find -name \*.ttf -exec mv {} $out/share/fonts/truetype/ \;
    '';
  };

  sf-mono = pkgs.stdenvNoCC.mkDerivation {
    name = "sf-mono";
    src = pkgs.fetchFromGitHub {
      owner = "shaunsingh";
      repo = "SFMono-Nerd-Font-Ligaturized";
      rev = "dc5a3e6";
      hash = "sha256-AYjKrVLISsJWXN6Cj74wXmbJtREkFDYOCRw1t2nVH2w=";
    };
    phases = [
      "installPhase"
    ];
    installPhase = ''
      mkdir -p $out/share/fonts/opentype
      cp -r $src/*.otf $out/share/fonts/opentype/
    '';
  };
in
{
  fonts.packages = with pkgs; [
    nerd-fonts.symbols-only
    feather
    sf-mono
    sf-pro
  ];
}
