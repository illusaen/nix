_: let
  packageNames = [
    "alacritty"
    "bat"
    "coreutils"
    "difftastic"
    "eza"
    "fd"
    "fzf"
    "gh"
    "git"
    "lsof"
    "ripgrep"
    "starship"
    "vim"
    "wget"
    "zoxide"
    "zsh"
  ];

  themeStateDir = "\${NIX_THEME_STATE_DIR:-\${XDG_STATE_HOME:-$HOME/.local/state}/nix-theme}";

  wrappedAlacritty = pkgs:
    pkgs.writeShellApplication {
      name = "alacritty";
      text = ''
        exec ${pkgs.alacritty}/bin/alacritty --config-file "${themeStateDir}/current/alacritty/alacritty.toml" "$@"
      '';
    };

  wrappedBat = pkgs:
    pkgs.writeShellApplication {
      name = "bat";
      text = ''
        export BAT_CONFIG_DIR="${themeStateDir}/current/bat"
        exec ${pkgs.bat}/bin/bat "$@"
      '';
    };

  shellPackages = pkgs: (builtins.filter (package: package != null) (map (
      name:
        if name == "alacritty"
        then
          if pkgs ? alacritty
          then wrappedAlacritty pkgs
          else null
        else if name == "bat"
        then
          if pkgs ? bat
          then wrappedBat pkgs
          else null
        else pkgs.${name} or null
    )
    packageNames));
in {
  imports = [];

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
  in {
    config = lib.mkMerge [
      {
        programs = {
          direnv = {
            enable = true;
            silent = true;
            nix-direnv.enable = true;
            settings = {
              hide_env_diff = true;
              whitelist.prefix = ["~/Projects"];
            };
          };

          git = {
            enable = true;
            config = {
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
          };

          nix-ld.enable = true;
          starship = {
            enable = true;
            settings = {
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
          };
          zsh = {
            enable = true;
            histFile = "$HOME/${historyFile}";
            shellAliases = {
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
            interactiveShellInit = ''
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
            '';
          };
        };

        environment.systemPackages = shellPackages pkgs;

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

  modules.darwin = {pkgs, ...}: {
    environment.systemPackages = shellPackages pkgs;

    programs.direnv = {
      enable = true;
      silent = true;
      nix-direnv.enable = true;
      settings = {
        hide_env_diff = true;
        whitelist.prefix = ["~/Projects"];
      };
    };
  };
}
