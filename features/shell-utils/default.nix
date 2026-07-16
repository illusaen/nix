let
  themeStateDir = "\${NIX_THEME_STATE_DIR:-\${XDG_STATE_HOME:-$HOME/.local/state}/nix-theme}";

  mkGitConfig = {
    host,
    user,
    userName,
  }: {
    core.sshCommand = "ssh -i ${host.privateKey}";
    diff.external = "difft --color auto --background dark --display side-by-side";
    init.defaultBranch = "main";
    pull.rebase = true;
    push.autoSetupRemote = true;
    user = {
      email = user.identity.email or "";
      name = user.identity.displayName or userName;
    };
    credential = {
      helper = "!gh auth git-credential";
      username = user.identity.accountName or userName;
    };
  };

  starshipSettings = {
    add_newline = true;
    format = "$directory$hostname$fill$git_branch $git_status$direnv$nodejs$python$c$cmd_duration$time$line_break$character";
    character = {
      success_symbol = "[lambda](bold green)";
      error_symbol = "[x](bold red)";
    };
    cmd_duration = {
      min_time = 500;
      format = "[$duration  ](yellow)";
    };
    directory = {
      home_symbol = "~";
      truncation_length = 3;
      truncation_symbol = ".../";
    };
    fill.symbol = " ";
    git_branch.format = "[$branch](bold)";
    git_status = {
      ignore_submodules = true;
      format = "[$all_status$ahead_behind  ](red)";
    };
    hostname = {
      disabled = false;
      ssh_only = true;
      format = "[$hostname](red)";
    };
    time = {
      disabled = false;
      format = "[$time]";
      time_format = "%H:%M";
    };
  };

  zshAliases = {
    cat = "bat";
    e = "open_editor";
    eza = "eza --icons=auto --git --git-repos";
    fd = "fd --hidden --follow --exclude .git";
    ga = "git add -A";
    gb = "git branch";
    gcm = "git_commit_with_message";
    gcma = "git commit -m";
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
  };

  mkZshInit = pkgs: ''
    eval "$(${pkgs.zoxide}/bin/zoxide init zsh --cmd n)"
    source <(${pkgs.fzf}/bin/fzf --zsh)

    WORDCHARS=''${WORDCHARS:s#/#}

    bindkey '^[b' backward-word
    bindkey '^[f' forward-word
    bindkey '^[[1;5D' backward-word
    bindkey '^[[1;5C' forward-word
    bindkey '^W' backward-kill-word

    zmodload zsh/terminfo
    [[ -n "''${terminfo[khome]}" ]] && bindkey "''${terminfo[khome]}" beginning-of-line
    [[ -n "''${terminfo[kend]}" ]] && bindkey "''${terminfo[kend]}" end-of-line
    [[ -n "''${terminfo[kdch1]}" ]] && bindkey "''${terminfo[kdch1]}" delete-char
    bindkey '^[[H' beginning-of-line
    bindkey '^[[F' end-of-line
    bindkey '^[[1~' beginning-of-line
    bindkey '^[[4~' end-of-line
    bindkey '^[[7~' beginning-of-line
    bindkey '^[[8~' end-of-line
    bindkey '^[[3~' delete-char

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
      git commit -m "$1"
    }

    nix_store_for_command() {
      if [ "$#" -ne 1 ]; then
        echo "Usage: nix_store_for_command <command>" >&2
        return 2
      fi

      local command_path resolved_path store_name store_dir
      if ! command_path="$(command -v -- "$1" 2>/dev/null)"; then
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

  mkDarwinZshInit = pkgs: ''
    export STARSHIP_CONFIG=/etc/starship.toml
    eval "$(${pkgs.starship}/bin/starship init zsh)"

    ${mkZshInit pkgs}
  '';
in {
  # imports = [./starship.nix ./zsh.nix];

  modules.generic = {pkgs, ...}: {
    programs.direnv = {
      enable = true;
      silent = true;
      nix-direnv.enable = true;
      settings = {
        hide_env_diff = true;
        whitelist.prefix = ["~/Projects"];
      };
    };

    environment.systemPackages = with pkgs; [
      coreutils
      difftastic
      eza
      fd
      fzf
      gh
      git
      ripgrep
      starship
      vim
      wget
      zoxide
      zsh

      (
        writeShellApplication {
          name = "bat";
          text = ''
            export BAT_CONFIG_DIR="${themeStateDir}/current/bat"
            exec ${bat}/bin/bat "$@"
          '';
        }
      )
      (
        writeShellApplication {
          name = "alacritty";
          text = ''
            exec ${alacritty}/bin/alacritty --config-file "${themeStateDir}/current/alacritty/alacritty.toml" "$@"
          '';
        }
      )
    ];
  };

  modules.nixos = {
    host,
    lib,
    options,
    pkgs,
    user,
    ...
  }: let
    userName = user.name or "wendy";
    historyFile = ".local/state/.zsh_history";
    gitConfig = mkGitConfig {inherit host user userName;};
    ghConfig = pkgs.writeText "gh-config.yml" ''
      version: "1"
    '';
    ghHosts = pkgs.writeText "gh-hosts.yml" ''
      github.com:
        git_protocol: ssh
        users:
          ${user.identity.accountName or userName}:
        user: ${user.identity.accountName or userName}
    '';
  in {
    config = lib.mkMerge [
      {
        programs = {
          git = {
            enable = true;
            config = gitConfig;
          };

          nix-ld.enable = true;
          starship = {
            enable = true;
            settings = starshipSettings;
          };
          zsh = {
            enable = true;
            histFile = "$HOME/${historyFile}";
            shellAliases = zshAliases;
            interactiveShellInit = mkZshInit pkgs;
          };
        };

        hjem.users.${userName}.xdg.config.files = {
          "gh/config.yml".source = ghConfig;
          "gh/hosts.yml".source = ghHosts;
        };

        users.users.${userName}.shell = pkgs.zsh;
      }

      (lib.mkIf (options ? persistUser) {
        persistUser = {
          directories = [".local/share/zoxide"];
          files = [
            {
              file = historyFile;
              how = "symlink";
            }
          ];
        };
      })
    ];
  };

  modules.darwin = {
    host,
    lib,
    pkgs,
    user,
    ...
  }: let
    userName = user.name or host.owner;
    gitConfig = mkGitConfig {inherit host user userName;};
    starshipConfig = (pkgs.formats.toml {}).generate "starship.toml" starshipSettings;
  in {
    environment = {
      etc.gitconfig.text = lib.generators.toGitINI gitConfig;
      etc."starship.toml".source = starshipConfig;
      shellAliases = zshAliases;
    };

    programs = {
      zsh = {
        enable = true;
        histFile = "$HOME/.local/state/.zsh_history";
        interactiveShellInit = mkDarwinZshInit pkgs;
      };
    };
  };
}
