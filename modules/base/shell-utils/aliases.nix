{
  flake.modules.generic.shell-utils = {
    environment.shellAliases = {
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

    environment.interactiveShellInit = ''
      git_commit_with_message() {
        git commit -m \""$1"\"
      }

      open_editor() {
        for editor in zed nvim vim; do
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
