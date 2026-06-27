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
    };
  };
}
