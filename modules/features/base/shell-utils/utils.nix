{
  flake.modules.generic.shell-utils = {pkgs, ...}: {
    programs.direnv = {
      enable = true;
      silent = true;
      nix-direnv.enable = true;
      settings = {
        hide_env_diff = true;
        whitelist.prefix = ["~/Projects"];
      };
    };

    programs.nix-ld.enable = true;

    environment.systemPackages = with pkgs; [
      coreutils
      eza
      fd
      fzf
      lsof
      ripgrep
      vim
      wget
      zoxide
    ];

    persistUser.directories = [".local/share/zoxide"];
  };
}
