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
        pkgs.inkscape
      ]
      ++ optionalPackage "bambu-studio"
      ++ optionalPackage "image-roll"
      ++ optionalPackage "onlyoffice-desktopeditors";

    xdg.mime.defaultApplications."image/*" = "com.github.weclaw1.ImageRoll.desktop";
  };

  modules.darwin = _: {};
}
