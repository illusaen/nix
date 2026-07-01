# Build Performance Cleanup

This audit looks for places where the configuration evaluates or builds more
than the selected host needs. The main goal is shorter local rebuilds and
simpler reasoning about why a package is in a host closure.

## Current Shape

The flake imports the whole module tree with `import-tree`. Individual host
systems are then built from named modules:

- `odin`: `base`, `boot`, `hardware`, `wendy`, `desktop-shell`, `programs`,
  `theming`, `preservation`, `nvidia`
- `huginn`: `base`, `boot`, `hardware`, `wendy`, `services`, `preservation`
- `muninn`: `base`, `boot`, `hardware`, `wendy`, `services`, `preservation`

Role-based host defaults are working, but several imported feature groups are
too broad.

## Highest Impact Cleanup

### Split Desktop Hardware From Server Hardware

`hardware` currently imports:

```nix
[
  "audio"
  "bluetooth"
  "networking"
  "facter"
]
```

Because every host gets `hardware`, servers also get desktop audio and
Bluetooth behavior:

- `pavucontrol`
- `playerctld`
- PipeWire 32-bit ALSA support
- `blueman`
- Bluetooth persistence

This is unnecessary for `huginn` and `muninn`.

Recommended change:

- Keep `hardware = [ "networking" "facter" ]`.
- Add a new `desktop-hardware = [ "audio" "bluetooth" ]`.
- Add `desktop-hardware` only for hosts with `tags.role = "desktop"`.

This should reduce server closures and make server rebuilds less likely to pull
desktop packages.

### Move Fonts Out Of Base

`base` imports `fonts`, and `fonts` installs the full UI font set:

- Font Awesome
- Maple Mono NF CN
- Inter
- Monaspace
- Noto Color Emoji
- Material Symbols

That is useful for desktops, but headless server hosts usually do not need it.

Recommended change:

- Remove `fonts` from `base`.
- Add `fonts` to `desktop-shell` or `theming`.
- If a server needs fonts for a service later, add a service-specific font
  module instead of making fonts global.

### Split Desktop Programs Into Smaller Groups

`programs` currently imports a large desktop bundle:

```nix
[
  "one-password"
  "zed"
  "meld"
  "firefox"
  "autostart"
  "codex"
  "images"
  "zathura"
  "steam"
  "ytmdesktop"
  "bambu-studio"
]
```

This makes `odin` install everything in the bundle even if the current task only
needs a smaller workstation profile. Heavy or frequently changing packages in
this group include:

- Steam
- Bambu Studio
- Firefox
- Codex desktop
- image/graphics applications

Recommended change:

- Keep a small `programs` or `desktop-apps-core` module for daily tools.
- Split heavier apps into named modules such as `gaming`, `printing-3d`,
  `creative-apps`, and `ai-tools`.
- Add those module names explicitly on the host.

This improves rebuild control: changing or rebuilding one app group does not
implicitly belong to every desktop host.

## Evaluation Cleanup

### Remove Unused Module Settings Provenance

`system-configurations.nix` computes:

- fleet-level module settings
- host-level module settings
- user-level module settings
- provenance for all three

Only `moduleSettings` is used outside the resolver today. No module currently
uses `moduleSettingsProvenance`, `fleet.moduleSettings`, or
`user.moduleSettings`.

Recommended change:

- Compute only host-level `moduleSettings` by default.
- Remove `moduleSettingsProvenance` from `specialArgs` until a consumer exists.
- Do not resolve fleet/user settings separately unless a module actually needs
  those views.

This removes multiple `lib.evalModules` calls per host during evaluation.

### Keep Host-Specific Wrappers Out Of Global Package Builds

Host-specific wrappers now use the correct pattern:

```nix
pkgs.local.niri.passthru.wrap {
  _module.args = {
    inherit fleet moduleSettings;
  };
}
```

The tradeoff is that `niri` and `noctalia-wrapped` still also exist as global
base packages under `packages.<system>`. Those base packages exist so the host
can call `passthru.wrap`, but they are not the final host-specific packages.

Recommended future simplification:

- Add `self` to host `specialArgs`.
- Build host wrappers from `self.wrappers.<name>.wrap { inherit pkgs; ... }`.
- Exclude host-only wrapper bases from `perSystem.wrappers.packages`.

That would avoid exporting and building base variants that are not meant to be
installed directly.

## Package Output Cleanup

`packages.x86_64-linux` currently includes both local packages and selected
heavy upstream packages:

- `bambu-studio`
- `llama-cpp` with CUDA
- `noctalia`
- all wrapper packages

Exporting a package does not mean `nix flake check` builds it by default, but it
does make it easy for CI or cache jobs to build more than a host rebuild needs.

Recommended change:

- Keep hand-maintained local packages in `packages`.
- Move cache-only upstream packages behind an explicit cache workflow or a
  documented package group.
- Reuse exported heavy packages from modules when they are intentionally
  exported. For example, if `packages.llama-cpp` stays, the service module
  should use `pkgs.local.llama-cpp` instead of repeating
  `pkgs.llama-cpp.override { cudaSupport = true; }`.

## Check Output Cleanup

`checks` currently include full NixOS toplevel builds:

- `checks.x86_64-linux.configurations:nixos:huginn`
- `checks.x86_64-linux.configurations:nixos:odin`
- `checks.aarch64-linux.configurations:nixos:muninn`

This is useful for confidence, but expensive when `nix flake check` is used as a
fast local validation command.

Recommended change:

- Split fast checks from full system build checks.
- Keep formatting, schema, and evaluation checks in default `checks`.
- Move full host toplevel builds to a separate explicit command or CI job, such
  as `nix build .#nixosConfigurations.odin.config.system.build.toplevel`.

This makes local validation faster while preserving full build coverage when it
is intentionally requested.

## Smaller Cleanups

- `base` imports `autostart`, but only graphical sessions use it. Move it to
  `desktop-shell` or `programs`.
- `environment.systemPackages` contains duplicates such as multiple `zsh`
  entries. Nix store closures deduplicate by path, so this is mostly readability,
  but cleaning it up makes package origins easier to inspect.
- `modules/features/programs/steam.nix` has `homebrew.cashs`, which looks like a
  typo for `homebrew.casks`. This is not a Linux build-time issue, but it is dead
  configuration.

## Suggested Implementation Order

1. Split `hardware` into common and desktop-only hardware.
2. Move `fonts` and `autostart` out of `base`.
3. Simplify module settings resolution and remove unused provenance.
4. Split `programs` into smaller desktop app groups.
5. Decide whether heavy upstream packages should remain exported.
6. Decide whether full host builds belong in default `checks`.
7. Refactor host-specific wrappers to avoid exporting unused base packages.

## Verification Commands

Use these after each cleanup step:

```sh
nix eval --impure --json --expr 'let f = builtins.getFlake "path:/home/wendy/Projects/nix"; in builtins.mapAttrs (_: h: h.moduleNames) f.evaluation.config.fleet.hosts'
nix eval --impure --json --expr 'let f = builtins.getFlake "path:/home/wendy/Projects/nix"; in map (p: p.name or null) f.nixosConfigurations.huginn.config.environment.systemPackages'
nix eval --impure --expr '(builtins.getFlake "path:/home/wendy/Projects/nix").nixosConfigurations.odin.config.system.build.toplevel.drvPath'
```

For closure size comparisons, build the target first and then inspect it:

```sh
nix build .#nixosConfigurations.huginn.config.system.build.toplevel
nix path-info -rSh ./result
```
