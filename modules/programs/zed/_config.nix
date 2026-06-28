{lib, context7ApiKey, mono, icon, sizeBuffer, sizeUi, scheme, sans}: {
    agent_servers.Codex.command = "codex-acp";
    context_server = {
      mcp-server-context7 = {
        source = "extension";
        enabled = true;
        settings.context7_api_key = context7ApiKey;
      };
    };
    auto_install_extensions = {
      html = true;
      lua = true;
      toml = true;
      sql = true;
      nix = true;
      ini = true;
      mustache = true;
    };
    autosave.after_delay.milliseconds = 5000;
    auto_signature_help = true;
    auto_update = false;
    buffer_font_family = mono;
    buffer_font_features =
      {
        calt = true;
        liga = true;
      }
      // ((lib.range 1 10) |> map (n: {name = "ss${lib.fixedWidthNumber 2 n}";
      value = true;}) |> builtins.listToAttrs);
    buffer_font_fallbacks = [icon];
    buffer_font_size = sizeBuffer;
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
    languages.Nix.language_servers = ["nixd" "!nil"];
    formatter.external = {
      command = "treefmt";
      arguments = [
        "--stdin"
        "{buffer_path}"
      ];
    };
    diagnostics.inline.enabled = true;
    git.inline_blame.enabled = false;
    indent_guides.coloring = "indent_aware";
    profiles = {
      Web.settings = {
        auto_install_extensions = {
          deno = true;
          svelte = true;
          scss = true;
        };
      };
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
      themeName = "Base24 ${scheme."scheme-name"}";
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
    ui_font_family = sans;
    ui_font_features.calt = true;
    ui_font_fallbacks = [icon];
    ui_font_size = sizeUi;
}
