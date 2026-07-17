{
  imports = [./vscode ./zathura.nix];

  modules.nixos = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [meld codex];

    persistUser.directories = [
      ".codex"
    ];
  };

  modules.darwin = {
    homebrew.casks = ["codex-app"];
  };
}
