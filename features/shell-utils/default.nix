let
  themeStateDir = "\${NIX_THEME_STATE_DIR:-\${XDG_STATE_HOME:-$HOME/.local/state}/nix-theme}";
in {
  imports = [./git.nix ./starship.nix ./zsh.nix];

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
      eza
      fd
      fzf
      ripgrep
      neovim
      wget
      zoxide
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
    lib,
    options,
    ...
  }:
    lib.mkMerge [
      {
        programs.nix-ld.enable = true;
      }
      (lib.mkIf (options ? persistUser) {
        persistUser.directories = [".local/share/zoxide"];
      })
    ];
}
