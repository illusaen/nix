{
  wlib,
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) mkOption types;
  fontType = types.submodule {
    options = {
      icon = mkOption {type = types.str;};
      mono = mkOption {type = types.str;};
      sans = mkOption {type = types.str;};
      size = mkOption {
        type = types.int;
        apply = v: builtins.floor (v * 4 / 3 + 0.5);
      };
    };
  };
in {
  imports = [wlib.modules.default];
  options = {
    fonts = mkOption {type = fontType;};
    scheme = mkOption {type = types.raw;};
    dataDir = mkOption {
      type = types.str;
      default = "\${XDG_DATA_HOME:-$HOME/.local/share}/zed-wrapped";
      description = "Runtime-writable Zed user data directory. Environment variables are expanded.";
    };
  };

  config.flags."--user-data-dir" = {
    data = config.dataDir;
    esc-fn = wlib.escapeShellArgWithEnv;
  };
  config.binName = "zed";
  config.aliases = ["zeditor"];
  config.package = pkgs.zed-editor;
  config.constructFiles.generatedConfig = {
    relPath = "settings.json";
    content = builtins.toJSON {
      agent_servers.Codex.command = "codex-acp";
      context_server = {
        mcp-server-context7 = {
          source = "extension";
          enabled = true;
          settings.context7_api_key = "ctx7sk-b83e3e96-0c74-451c-9926-c966f3d81afe";
        };
      };
      auto_install_extensions = {
        html = true;
        lua = true;
        fish = true;
        deno = true;
        svelte = true;
        toml = true;
        sql = true;
        scss = true;
        nix = true;
        ini = true;
        mustache = true;
      };
      autosave.after_delay.milliseconds = 5000;
      auto_signature_help = true;
      auto_update = false;
      buffer_font_family = config.fonts.mono;
      buffer_font_features =
        {
          calt = true;
          liga = true;
        }
        // lib.pipe (lib.range
          1
          10) [
          (map (n: {
            name = "ss${lib.fixedWidthNumber 2 n}";
            value = true;
          }))
          builtins.listToAttrs
        ];
      buffer_font_fallbacks = [config.fonts.icon];
      buffer_font_size = config.fonts.size;
      code_lens = "on";
      diff_view_style = "unified";
      load_direnv = "shell_hook";
      show_tab_bar_buttons = false;
      tabs = {
        git_status = true;
        show_diagnostics = "all";
      };
      session.trust_all_worktrees = true;
      extend_comment_on_newline = false;
      lsp = {};
      formatter.external.command = "treefmt";
      diagnostics.inline.enabled = true;
      git.inline_blame.enabled = false;
      indent_guides.coloring = "indent_aware";
      profiles = {
        Web.settings = {
          buffer_font_size = 20;
        };
        Rust.settings = {};
        Nix.settings = {};
      };
      preview_tabs.enabled = false;
      preferred_line_length = 120;
      projects_online_by_default = false;
      resize_all_panels_in_dock = ["left" "right" "bottom"];
      search.center_on_match = true;
      semantic_tokens = "combined";
      document_folding_ranges = "on";
      document_symbols = "on";
      use_smartcase_search = true;
      show_call_status_icon = false;
      soft_wrap = "editor_width";
      tab_size = 2;
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
      terminal = {
        copy_on_select = true;
        cursor_shape = "bar";
      };
      theme = let
        themeName = "Base24 ${config.scheme."scheme-name"}";
      in {
        dark = themeName;
        light = themeName;
      };
      title_bar = {
        show_branch_status_icon = true;
        show_onboarding_banner = false;
        show_user_picture = false;
        show_user_menu = false;
        show_sign_in = false;
      };
      project_panel = {
        dock = "right";
        entry_spacing = "standard";
        bold_folder_labels = true;
      };
      collaboration_panel.button = false;
      debugger.dock = "right";
      outline_panel.button = false;
      ui_font_family = config.fonts.sans;
      ui_font_features.calt = true;
      ui_font_fallbacks = [config.fonts.icon];
      ui_font_size = config.fonts.size;
    };
  };
  config.constructFiles.generatedTheme = let
    theme = config.scheme {
      template = ./zed-base24.json.mustache;
      extension = ".json";
    };
  in {
    relPath = "themes/base24-theme.json";
    builder = ''
      mkdir -p "$(dirname "$2")"
      ln -s ${lib.escapeShellArg theme} "$2"
    '';
  };
  config.runShell = [
    ''
      zed_data_dir=${wlib.escapeShellArgWithEnv config.dataDir}
      ${pkgs.coreutils}/bin/mkdir -p "$zed_data_dir/config/themes"
      ${pkgs.coreutils}/bin/rm -f "$zed_data_dir/settings.json" "$zed_data_dir/themes/base24-theme.json"
      ${pkgs.coreutils}/bin/install -m 0644 ${lib.escapeShellArg config.constructFiles.generatedConfig.path} "$zed_data_dir/config/settings.json"
      ${pkgs.coreutils}/bin/install -m 0644 ${lib.escapeShellArg config.constructFiles.generatedTheme.path} "$zed_data_dir/config/themes/base24-theme.json"
    ''
  ];
}
