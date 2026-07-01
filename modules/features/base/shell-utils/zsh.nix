let
  historyFile = ".local/state/.zsh_history";
in {
  flake.modules.nixos.zsh = {
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

      dot_cd_accept_line() {
        emulate -L zsh

        if [[ "$BUFFER" =~ '^[[:space:]]*(\.{2,})[[:space:]]*$' ]]; then
          local cmd="$match[1]"
          local levels=$((''${#cmd} - 1))
          local target="$PWD"

          while (( levels > 0 )) && [[ "$target" != "/" ]]; do
            target="''${target:h}"
            ((levels--))
          done

          BUFFER="cd -- ''${(q)target}"
        fi

        zle .accept-line
      }
      zle -N accept-line dot_cd_accept_line

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
