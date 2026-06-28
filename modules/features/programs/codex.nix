{inputs, ...}: {
  flake-file.inputs.codex-desktop-linux = {
    url = "github:ilysenko/codex-desktop-linux";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  flake.modules.nixos.codex = {pkgs, ...}: {
    imports = [inputs.codex-desktop-linux.nixosModules.default];
    environment.systemPackages = with pkgs; [codex codex-acp];
  };

  flake.modules.nixos.codex-desktop = {
    imports = [inputs.codex-desktop-linux.nixosModules.default];
    programs.codexDesktopLinux = {
      enable = true;
      computerUseUi.enable = true;
      remoteMobileControl.enable = true;
      remoteControl.enable = true;
    };
  };

  flake.modules.darwin.codex.homebrew.casks = ["codex-app"];
}
