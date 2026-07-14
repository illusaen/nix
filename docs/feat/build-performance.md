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

### Use Unique Flake Systems

Status: implemented.

`systems` is now derived from the host platforms with `lib.unique`. Before this,
the evaluated systems list contained `x86_64-linux` twice because both `odin`
and `huginn` use that platform:

```nix
["x86_64-linux" "aarch64-linux" "x86_64-linux"]
```

This is mostly a flake output cleanup; concrete timing did not show a material
change for `odin`'s NixOS toplevel eval.

### Prefer Read-Only Eval For DrvPath Checks

Status: recommended.

For eval-only probes that read `config.system.build.toplevel.drvPath`, Lix/Nix
spends a large part of the time instantiating derivations in the store. Passing
`--read-only` avoids that work while still proving the expression evaluates.

Measured on this repo:

- `odin` drvPath: about `9.8s` normally, about `5.4s` with `--read-only`
- `huginn` drvPath: about `6.2s` normally, about `3.7s` with `--read-only`

Use this for quick evaluation checks:

```sh
nix eval --read-only --impure .#nixosConfigurations.odin.config.system.build.toplevel.drvPath
```

Do not use `--read-only` as a substitute for build or switch commands; it is
only for eval timing and smoke checks.

### Remove Per-Host Settings Resolver

Status: implemented.

`system-configurations.nix` no longer builds a separate per-host settings schema.
Host-specific facts live in the host schema, and module-local behavior uses
normal NixOS/Darwin module options. This removes the extra `lib.evalModules`
pass per host.

### Keep Host-Specific Wrappers Out Of Global Package Builds

Status: implemented for the active plain fleet path.

Legacy host-specific flake wrappers used this pattern:

```nix
self.wrappers.niri.wrap {
  inherit pkgs;
  _module.args = {
    inherit fleet;
    inherit (host) monitors;
  };
}
```

The active plain path no longer depends on those host-specific wrapper package
outputs. Niri settings are rendered directly by `features/desktop-shell`, and
Noctalia uses its upstream NixOS module plus runtime theme profile config.

## Package Output Cleanup

The plain package output is intentionally limited to hand-maintained local
packages under `packages/`. Heavy upstream packages are built through the host
configuration or explicit cache workflow targets instead of being exported from
the local package set.

Implemented:

- `llama-cpp` service now uses one feature-local CUDA-enabled override for both
  `environment.systemPackages` and `services.llama-cpp.package`.
- `noctalia-wrapped` is no longer exported as a default package.
- `niri` still remains exported because `niri-scripts` uses it.
- `.github/workflows/nix-cache.yml` explicitly builds the configured
  `odin.config.services.llama-cpp.package` so Cachix has a named CUDA
  `llama-cpp` target before the full `odin` toplevel build.

Still recommended:

- Keep hand-maintained local packages in `packages`.
- Add more explicit cache workflow targets when a large upstream dependency is
  important enough to cache outside the full host toplevel.

## Check Output Cleanup

Status: implemented, then simplified further.

Default `checks` no longer include full NixOS toplevel builds. The secondary
`hostBuilds` aggregate was removed because it traversed every host
configuration to expose aliases that were not used by the repo.

Use the normal configuration targets for explicit full builds:

```sh
nix build .#nixosConfigurations.odin.config.system.build.toplevel
```

## Smaller Cleanups

- `autostart` is desktop-only. `tailscale-systray` was split out so the
  Tailscale daemon can stay in `base` without depending on `systemdAutostart`.
- Repo-owned `environment.systemPackages` duplication was cleaned up for `zsh`.
  Remaining duplicate paths come from upstream NixOS modules, such as filesystem
  tools, firewall/nftables helpers, user/group management, and shell defaults.
  Nix store closures deduplicate by path, so these are mostly readability noise.
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
4. Investigate upstream NixOS duplicate package paths only if they become
   operationally confusing; the repo-owned duplicate has been removed.

## Verification Commands

Use these after each cleanup step:

```sh
nix eval --impure --json --expr 'let f = builtins.getFlake "path:/home/wendy/Projects/nix"; in builtins.mapAttrs (_: h: h.moduleNames) f.evaluation.config.fleet.hosts'
nix eval --impure --json --expr 'let f = builtins.getFlake "path:/home/wendy/Projects/nix"; in map (p: p.name or null) f.nixosConfigurations.huginn.config.environment.systemPackages'
nix eval --impure --expr '(builtins.getFlake "path:/home/wendy/Projects/nix").nixosConfigurations.odin.config.system.build.toplevel.drvPath'
nix eval --impure --json --expr 'let f = builtins.getFlake "path:/home/wendy/Projects/nix"; in builtins.attrNames f.checks.x86_64-linux'
```

For closure size comparisons, build the target first and then inspect it:

```sh
nix build .#nixosConfigurations.huginn.config.system.build.toplevel
nix path-info -rSh ./result
```
