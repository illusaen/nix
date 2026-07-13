_: {
  imports = [];

  modules.nixos = {
    lib,
    pkgs,
    ...
  }: let
    optionalPackage = name:
      lib.optional (pkgs ? ${name}) pkgs.${name};
  in {
    environment.systemPackages =
      [
        pkgs.meld
        pkgs.zathura
      ]
      ++ optionalPackage "codex"
      ++ optionalPackage "codex-acp"
      ++ optionalPackage "zed-editor";

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
