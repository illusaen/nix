{
  flake.modules.nixos.nautilus = {pkgs, ...}: {
    services.gvfs.enable = true;
    services.udisks2.enable = true;
    services.gnome.sushi.enable = true;

    programs.nautilus-open-any-terminal = {
      enable = true;
      terminal = "alacritty";
    };

    nixpkgs.overlays = [
      (_final: prev: {
        nautilus = prev.nautilus.overrideAttrs (nprev: {
          buildInputs =
            nprev.buildInputs
            ++ (with pkgs.gst_all_1; [
              gst-plugins-good
              gst-plugins-bad
            ]);
        });
      })
    ];

    environment.systemPackages = with pkgs; [
      nautilus
      libheif
    ];

    environment.pathsToLink = ["share/thumbnailers"];
  };
}
