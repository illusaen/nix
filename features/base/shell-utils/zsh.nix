let
  historyFile = ".local/state/.zsh_history";
  shellAliases = {
    cat = "bat";
    e = "open_editor";
    eza = "eza --icons=auto --git --git-repos";
    fd = "fd --hidden --follow --exclude .git";
    ga = "git add -A";
    gb = "git branch";
    gcm = "git_commit_with_message";
    gcma = "git commit --amend";
    gco = "git checkout";
    gd = "git diff";
    gf = "git fetch";
    gl = "git pull";
    glg = "git log";
    gp = "git push";
    gpf = "git push --force-with-lease";
    gst = "git status";
    l = "eza -alg";
    ll = "eza --tree --git-ignore --all";
    whichstore = "nix_store_for_command";
    nd = "dix /run/current-system";
  };
in {
  modules = {
    generic = {
      pkgs,
      user,
      ...
    }: {
      users.users.${user.name}.shell = pkgs.zsh;
      programs.zsh = {
        enable = true;
        histFile = "$HOME/${historyFile}";
        interactiveShellInit = ''
          eval "$(${pkgs.zoxide}/bin/zoxide init zsh --cmd n)"
          source <(${pkgs.fzf}/bin/fzf --zsh)

          ${builtins.readFile ./interactive.zsh}
        '';
        promptInit = ''
          eval "$(${pkgs.starship}/bin/starship init zsh)"
        '';
      };
    };

    nixos = {
      lib,
      options,
      ...
    }:
      lib.mkMerge [
        {
          programs.zsh.shellAliases = shellAliases;
        }
        (lib.mkIf (options ? persistUser) {
          persistUser.files = [
            {
              file = historyFile;
              how = "symlink";
            }
          ];
        })
      ];

    darwin = {
      environment.shellAliases = shellAliases;
    };
  };
}
