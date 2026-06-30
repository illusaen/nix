{inputs, ...}: {
  flake-file.inputs.firefox-addons = {
    url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  flake.modules.darwin.firefox.homebrew.casks = ["firefox"];

  flake.modules.nixos.firefox = {lib, ...}: {
    nixpkgs.overlays = [inputs.firefox-addons.overlays.default];
    persistUser.directories = [".config/mozilla/firefox"];
    xdg.mime.defaultApplications = let
      application = "firefox.desktop";
      mimeTypes = [
        "text/html"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "x-scheme-handler/about"
      ];
    in
      lib.genAttrs mimeTypes (_: application);

    programs.firefox.enable = true;
  };
}
