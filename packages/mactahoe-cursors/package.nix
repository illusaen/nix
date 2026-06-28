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

    install -dm 755 dist/ $out/share/icons/MacTahoe-Cursors
    # cp -r dist/* $out/share/icons/MacTahoe-Cursors

    install -dm 755 dist-dark/ $out/share/icons/MacTahoe-dark-Cursors
    # cp -r dist-dark/* $out/share/icons/MacTahoe-dark-Cursors

    runHook postInstall
  '';
}
