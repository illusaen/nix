{self, ...}: let
  historyFile = ".local/state/.zsh_history";
in {
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

  flake.modules.generic.zsh = {
    pkgs,
    user,
    ...
  }: {
    users.users.${user.name}.shell = pkgs.local.zsh or pkgs.zsh;
    environment.systemPackages = [(pkgs.local.zsh or pkgs.zsh)];
  };

  flake.wrappers.zsh = {
    wlib,
    lib,
    pkgs,
    ...
  }: {
    imports = [wlib.wrapperModules.zsh];
    zshAliases = {
      eza = "eza --icons=auto --git --git-repos";
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
      whichstore = "nix_store_for_command";
    };
    zshrc.content = ''
      eval "$(${lib.getExe pkgs.zoxide} init zsh --cmd n)"
      eval "$(${lib.getExe pkgs.local.starship} init zsh)"
      source <(fzf --zsh)

      HISTFILE=$HOME/${historyFile}
      WORDCHARS=''${WORDCHARS:s#/#}

      bindkey '^[b' backward-word
      bindkey '^[f' forward-word
      bindkey '^[[1;5D' backward-word
      bindkey '^[[1;5C' forward-word
      bindkey '^W' backward-kill-word

      git_commit_with_message() {
        git commit -m \""$1"\"
      }

      nix_store_for_command() {
        if [[ $# -ne 1 ]]; then
          echo "Usage: nix_store_for_command <command>" >&2
          return 2
        fi

        local command_path resolved_path store_name store_dir
        if ! command_path="$(which -- "$1" 2>/dev/null)"; then
          echo "Command not found: $1" >&2
          return 1
        fi

        resolved_path="$(readlink -f -- "$command_path")" || return

        if [[ "$resolved_path" != /nix/store/* ]]; then
          echo "$1 resolves outside /nix/store: $resolved_path" >&2
          return 1
        fi

        store_name="''${resolved_path#/nix/store/}"
        store_name="''${store_name%%/*}"
        store_dir="/nix/store/$store_name"

        command eza --icons=auto --git "$store_dir"
        echo "Store dir: $store_dir"
      }

      setopt autocd
      function command_not_found_handler() {
        local cmd="$1"

        # Check if the command consists entirely of dots and has at least 2 dots
        if [[ "$cmd" =~ ^\.{2,}$ ]]; then
          local dots=''${#cmd}
          local up_path=""

          # Calculate how many levels to move up (dots minus 1)
          local levels=$((dots - 1))

          # Count how many directories deep we currently are
          # Using a loop to find the exact slash count safely
          local current_depth=0
          local temp_pwd="$PWD"
          while [[ "$temp_pwd" != "/" ]]; do
            ((current_depth++))
            temp_pwd="''${temp_pwd%/*}"
          done

          # If requested levels exceed depth, cap it to current depth
          if [[ $levels -gt $current_depth ]]; then
            levels=$current_depth
          fi

          # If we are already at root, or levels capped to 0, just stay at /
          if [[ $levels -eq 0 ]]; then
            return 0
          fi

          # Build the path based on the safe number of levels
          for ((i=0; i<levels; i++)); do
            up_path="../$up_path"
          fi

          cd "$up_path"
          return 0
        fi

        # Fallback to standard command not found error
        echo "zsh: command not found: $cmd" >&2
        return 127
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

      autoload -Uz add-zsh-hook
      cd_ls_hook() {
        emulate -L zsh
        local file_count=( *(ND) )
        if (( $#file_count <= 50 )); then
          eza --icons=always --group-directories-first
        else
          echo "Large directory ($#file_count files). Skipped auto-ls."
        fi
      }
      add-zsh-hook chpwd cd_ls_hook
    '';
  };
}
