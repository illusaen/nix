# Fish shell configuration
{
  config,
  lib,
  helpers,
  pkgs,
  vars,
  ...
}:
let
  cfg = config.modules.fish;
in
{
  options.modules.fish = {
    enable = helpers.mkTrueOption "fish shell";
  };

  config = lib.mkIf cfg.enable {
    programs.fish = {
      enable = true;
      plugins = [
        {
          name = "colored-man-pages";
          src = pkgs.fishPlugins.colored-man-pages.src;
        }
        {
          name = "puffer";
          src = pkgs.fishPlugins.puffer.src;
        }
        {
          name = "autols";
          src = pkgs.fetchFromGitHub {
            owner = "kpbaks";
            repo = "autols.fish";
            rev = "fe2693e80558550e0d995856332b280eb86fde19";
            sha256 = "EPgvY8gozMzai0qeDH2dvB4tVvzVqfEtPewgXH6SPGs=";
          };
        }
        {
          name = "fzf";
          src = pkgs.fetchFromGitHub {
            owner = "PatrickF1";
            repo = "fzf.fish";
            rev = "v10.3";
            sha256 = "sha256-T8KYLA/r/gOKvAivKRoeqIwE2pINlxFQtZJHpOy9GMM=";
          };
        }
      ];
      shellAbbrs = rec {
        gst = "git status";
        gcm = {
          setCursor = true;
          expansion = "git commit -m \"%\"";
        };
        gco = "git checkout";
        ga = "git add -A";
        gl = "git log";
        gd = "git diff";
        gb = "git branch";
        gpl = "git pull";
        gp = "git push";
        gpc = "git push -u origin (git rev-parse --abbrev-ref HEAD)";
        gpf = "git push --force-with-lease";
        git_clone_own_repo = {
          function = "_git_clone_own_repo";
          regex = "^g(gc|r)l\$";
          setCursor = true;
        };

        rebuild = if pkgs.stdenv.isDarwin then "nh darwin switch ." else "nh os switch .";
        rehome = "nh home switch .";

        rmr = "rm -r";
        rmf = "rm -rf";

        cd = "j";
        cat = "bat";
        ncg = "sudo nix-collect-garbage -d";

        l = "eza -alg";
        ll = "eza";
        lt = "eza --tree --git-ignore --all";
      };
      shellAliases = {
      };
      functions = {
        fish_greeting = "";
        mkd = ''
          if test -n "$argv"
            mkdir -p $argv
            builtin cd $argv
          end
        '';

        tt =
          let
            dir = vars.dirs.projects;
          in
          ''
            cd ${dir}
            if test "$PWD" = "${dir}"
              if test -d ./test
                rm -rf test
              end
              mkdir test
              builtin cd test
            end
          '';

        _git_clone_own_repo = ''
          set --local base_url 'git@github.com:illusaen/'
          set --local default_result git clone $base_url'%.git'
          switch $argv
            case ggcl
              echo $default_result
            case grl
              set --local repo_name (gh repo list | fzf)
              if test -n "$repo_name" && string match -rq '^.+\/(?<repo>\S+).+$' $repo_name
                echo git clone $base_url$repo'.git'
              end
          end
        '';
      };
    };
  };
}
