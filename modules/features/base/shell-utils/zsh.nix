{self, ...}: let
  historyFile = ".local/state/.zsh_history";
in {
  flake.modules.generic.shell-utils = {pkgs, ...}: {environment.systemPackages = [(pkgs.local.zsh or pkgs.zsh)];};

  flake.modules.nixos.zsh = {
    imports = [self.nixosModules.zsh];
    wrappers.zsh = {
      enable = true;
      asSystemDefault = true;
    };
    persistUser.files = [
      {
        file = historyFile;
        how = "symlink";
      }
    ];
  };

  flake.modules.darwin.zsh = {
    pkgs,
    lib,
    config,
    ...
  }: {
    users.users = lib.mapAttrs (_user: {shell = pkgs.local.zsh or pkgs.zsh;}) config.users.users;
  };

  flake.wrappers.zsh = {
    wlib,
    lib,
    pkgs,
    ...
  }: {
    imports = [wlib.wrapperModules.zsh];
    zshAliases = {
      eza = "eza --icons=auto --git";
      fd = "fd --hidden --follow --exclude .git";
      l = "eza -alg";
      ll = "eza --tree --git-ignore --all";
      cat = "bat";
      gst = "git status";
      gco = "git checkout";
      ga = "git add -A";
      gf = "git fetch";
      gl = "git pull";
      gd = "git diff";
      gb = "git branch";
      glg = "git log";
      gp = "git push";
      gpf = "git push --force-with-lease";
      gcm = "git_commit_with_message";
      gcma = "git commit -m";
      e = "open_editor";
    };
    zshrc.content = ''
      eval "$(${lib.getExe pkgs.zoxide} init zsh --cmd n)"
      eval "$(${lib.getExe pkgs.local.starship} init zsh)"

      HISTFILE=$HOME/${historyFile}

      bindkey '^[b' backward-word
      bindkey '^[f' forward-word
      bindkey '^[[1;5D' backward-word
      bindkey '^[[1;5C' forward-word

      git_commit_with_message() {
        git commit -m \""$1"\"
      }

      open_editor() {
        for editor in zeditor nvim vim; do
          if command -v "$editor" >/dev/null 2>&1; then
            "$editor" .
            return
          fi
        done

        echo "Error: no supported editor found (zed, nvim, or vim)." >&2
        return 1
      }
    '';
  };
}
