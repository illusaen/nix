{sources, ...}: {
  modules.nixos = {pkgs, ...}: let
    noctaliaModule = sources.noctalia.outPath + "/nix/nixos-module.nix";
    noctaliaPackage = pkgs.callPackage (sources.noctalia.outPath + "/nix/package.nix") {};
  in {
    imports = [noctaliaModule];

    programs.noctalia = {
      enable = true;
      package = noctaliaPackage;
      recommendedServices.enable = true;
      systemd.enable = true;
    };

    systemd.user.services.noctalia.environment.NOCTALIA_CONFIG_HOME = "%h/.local/state/nix-theme/current";

    nix.settings = {
      extra-substituters = [
        "https://noctalia.cachix.org"
      ];
      extra-trusted-public-keys = [
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      ];
    };
  };
}
