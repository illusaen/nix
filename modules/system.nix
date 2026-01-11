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
      hash = "sha256-Lk14U5iLc03BrzO5IdjUwORADqwxKSSg6rS3OlH9aa4=";
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
  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];
      warn-dirty = false;
      substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
        "https://nixpkgs-unfree.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
      ];
    };
  };

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = _: true;
  };

  environment = {
    systemPackages = with pkgs; [
      coreutils
      vim
      home-manager
      nh
    ];
    shells = [ pkgs.fish ];
  };

  fonts.packages = with pkgs; [
    nerd-fonts.symbols-only
    feather
    sf-mono
    sf-pro
  ];

  services.onepassword-secrets = {
    enable = true;
    tokenFile = "/etc/opnix-token";
    users = [ vars.name ];

    secrets = {
      sshPrivateKey = {
        reference = "op://Service/SSH-Key-Nix/private key?ssh-format=openssh";
        path = "/etc/ssh/id_rsa";
        mode = "0644";
      };
      sshPublicKey = {
        reference = "op://Service/SSH-Key-Nix/public key";
        path = "/etc/ssh/id_rsa.pub";
        mode = "0644";
      };
    };
  };

  programs.fish.enable = true;
  programs._1password.enable = true;
}
