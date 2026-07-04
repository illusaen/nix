# Runtime Theming

Runtime themes are selected per user. Nix builds the declared theme profiles
reproducibly, and user state points at the active profile through:

```text
$XDG_STATE_HOME/nix-theme/current
```

Use `theme-select` to choose a profile with fuzzel, or switch directly:

```sh
theme-apply tokyo-night-moon
theme-apply catppuccin-latte
```

Other commands:

```sh
theme-current
theme-cycle
theme-cycle previous
theme-list
theme-list --json
```

`theme-apply` updates GTK and Qt config links, applies GNOME interface settings
when `gsettings` is available, and best-effort restarts user services that are
expected to reload theme-sensitive UI, currently `noctalia.service` and
`waybar.service`.

Theme-sensitive wrappers stay reproducible by reading config from the active
profile. The profile contents are still Nix-built store paths during normal
operation. For development, `theme-apply` can use a mutable profile root through
`NIX_THEME_PROFILE_DIR`.
