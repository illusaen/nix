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

Role-based host defaults are working. Several broad feature groups have already
been narrowed, and the remaining large bundle is the desktop `programs`
aggregator.

## Highest Impact Cleanup

### Split Desktop Hardware From Server Hardware

Status: implemented.

`hardware` now imports only common hardware modules:

```nix
[
  "networking"
  "facter"
]
```

Desktop-only hardware behavior now comes from `desktop-shell`:

```nix
[
  "audio"
  "bluetooth"
]
```

This removes explicit desktop audio and Bluetooth packages from server host
closures.

### Move Fonts Out Of Base

Status: implemented.

`fonts` moved out of `base` and into `desktop-shell`. The full UI font set is
now desktop-only:

- Font Awesome
- Maple Mono NF CN
- Inter
- Monaspace
- Noto Color Emoji
- Material Symbols

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

Status: implemented.

`system-configurations.nix` now computes only the host-level resolved
`moduleSettings` view that modules consume. `moduleSettingsProvenance` is no
longer injected.

The injected values are:

- `moduleSettings`
- `fleet.moduleSettings`
- `host.moduleSettings`
- `user.moduleSettings`

All currently point at the same resolved host view. This removes multiple
`lib.evalModules` calls per host during evaluation.

### Keep Host-Specific Wrappers Out Of Global Package Builds

Status: partially implemented.

Host-specific wrappers now use the correct pattern:

```nix
self.wrappers.niri.wrap {
  inherit pkgs;
  _module.args = {
    inherit fleet moduleSettings;
  };
}
```

`self` is injected into host module arguments. `noctalia-wrapped` is excluded
from `perSystem.wrappers.packages` because it is only used as a host-specific
wrapper base.

`niri` still remains exported because `niri-scripts` depends on `pkgs.local.niri`
as a runtime input.

## Package Output Cleanup

`packages.x86_64-linux` currently includes both local packages and selected
heavy upstream packages:

- `bambu-studio`
- `llama-cpp` with CUDA
- `noctalia`
- wrapper packages, except host-only wrapper bases

Exporting a package does not mean `nix flake check` builds it by default, but it
does make it easy for CI or cache jobs to build more than a host rebuild needs.

Implemented:

- `llama-cpp` service now uses `pkgs.local.llama-cpp`, so the CUDA override is
  defined once.
- `noctalia-wrapped` is no longer exported as a default package.
- `niri` still remains exported because `niri-scripts` uses it.

Still recommended:

- Keep hand-maintained local packages in `packages`.
- Move cache-only upstream packages behind an explicit cache workflow or a
  documented package group.

## Check Output Cleanup

Status: implemented.

Default `checks` no longer include full NixOS toplevel builds. Full host builds
are exposed under `hostBuilds`:

- `hostBuilds.x86_64-linux.configurations:nixos:huginn`
- `hostBuilds.x86_64-linux.configurations:nixos:odin`
- `hostBuilds.aarch64-linux.configurations:nixos:muninn`

This makes local `nix flake check` faster while preserving explicit full build
targets.

## Smaller Cleanups

- `autostart` is desktop-only. `tailscale-systray` was split out so the
  Tailscale daemon can stay in `base` without depending on `systemdAutostart`.
- `environment.systemPackages` contains duplicates such as multiple `zsh`
  entries. Nix store closures deduplicate by path, so this is mostly readability,
  but cleaning it up makes package origins easier to inspect.
- `modules/features/programs/steam.nix` has `homebrew.cashs`, which looks like a
  typo for `homebrew.casks`. This is not a Linux build-time issue, but it is dead
  configuration.

## Suggested Implementation Order

1. Split `programs` into smaller desktop app groups only if `odin` will stop
   importing some of them.
2. Decide whether cache-only upstream packages such as `bambu-studio` and
   `noctalia` should remain in default package outputs.
3. Fix `muninn` facter/hardware data so the aarch64 host no longer evaluates
   x86-only AMD microcode.
4. Clean duplicate package entries in `environment.systemPackages` for
   readability.

## Verification Commands

Use these after each cleanup step:

```sh
nix eval --impure --json --expr 'let f = builtins.getFlake "path:/home/wendy/Projects/nix"; in builtins.mapAttrs (_: h: h.moduleNames) f.evaluation.config.fleet.hosts'
nix eval --impure --json --expr 'let f = builtins.getFlake "path:/home/wendy/Projects/nix"; in map (p: p.name or null) f.nixosConfigurations.huginn.config.environment.systemPackages'
nix eval --impure --expr '(builtins.getFlake "path:/home/wendy/Projects/nix").nixosConfigurations.odin.config.system.build.toplevel.drvPath'
nix eval --impure --json --expr 'let f = builtins.getFlake "path:/home/wendy/Projects/nix"; in builtins.attrNames f.checks.x86_64-linux'
nix eval --impure --json --expr 'let f = builtins.getFlake "path:/home/wendy/Projects/nix"; in builtins.attrNames f.hostBuilds.x86_64-linux'
```

For closure size comparisons, build the target first and then inspect it:

```sh
nix build .#nixosConfigurations.huginn.config.system.build.toplevel
nix path-info -rSh ./result
```
