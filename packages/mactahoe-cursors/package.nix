{
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation {
  pname = "mactahoe-cursors";
  version = "2026-06-28";

  src = fetchFromGitHub {
    owner = "vinceliuice";
    repo = "MacTahoe-icon-theme";
    rev = "main";
    hash = "sha256-YCtpagkXhRwD9NJRvgskq7yf4qr4XqUxQYUfyKD7mUs=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/icons/MacTahoe-Cursors
    cp -r cursors/dist/. $out/share/icons/MacTahoe-Cursors/

    mkdir -p $out/share/icons/MacTahoe-dark-Cursors
    cp -r cursors/dist-dark/. $out/share/icons/MacTahoe-dark-Cursors/

    runHook postInstall
  '';
}
