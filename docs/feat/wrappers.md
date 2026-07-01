# Wrappers

This repo uses `nix-wrapper-modules` for portable wrapper derivations. There
are two wrapper declaration paths:

- `flake.wrappers` is the original upstream shape.
- `flake.fleetWrappers` is an opt-in fleet-aware shape.

Use `flake.wrappers` unless a wrapper needs fleet schema data during wrapper
evaluation.

## Original Shape

The upstream wrapper interface is unchanged:

```nix
{
  flake.wrappers.git = {
    package = pkgs.git;
    flags = [ "--no-pager" ];
  };
}
```

Function modules receive the usual wrapper module arguments, such as `pkgs`,
`lib`, `config`, and `wlib`. They do not receive `fleet`.

```nix
{
  flake.wrappers.fuzzel = { wlib, ... }: {
    imports = [ wlib.wrapperModules.fuzzel ];
  };
}
```

Keeping the original path matters because many wrappers are global package
definitions. They should not depend on fleet context when they only describe the
program, files, flags, or generated config for a wrapper derivation.

## Fleet-Aware Shape

Use `flake.fleetWrappers` when a wrapper needs fleet-level schema data:

```nix
{
  flake.fleetWrappers.waybar = { fleet, pkgs, ... }: {
    imports = [ ./wrappers/waybar/module.nix ];
    font = {
      sans = fleet.fonts.sans.name;
      mono = fleet.fonts.mono.name;
      icon = fleet.fonts.icon.name;
      size = fleet.fonts.sizes.applications;
    };
    scheme = (fleet.base16.scheme pkgs).withHashtag;
  };
}
```

`flake.fleetWrappers` is validated with `fleet` in module arguments, then its
module declarations are forwarded into `flake.wrappers`. The exported result is
still available through the normal output:

```text
self.wrappers.waybar
```

This gives wrappers access to fleet-level data without replacing the upstream
interface. Wrappers that do not need fleet context stay on `flake.wrappers`.

Avoid declaring the same wrapper name in both `flake.wrappers` and
`flake.fleetWrappers` unless the definitions are intentionally meant to merge
under the Nix module system.

## What Belongs In Fleet Context

Fleet-aware wrappers are appropriate for values that are global across the
fleet:

- font families and font sizes
- base16 scheme selection
- shared wrapper defaults
- shared command aliases or flags
- global monitor naming vocabulary

Fleet-aware wrappers are not enough for values that vary by host. A global
wrapper output has no single host identity, so injecting `host` into
`flake.wrappers` would be ambiguous.

## Host-Specific Wrapper Behavior

Host-specific wrapper behavior is anything that changes based on the machine
that will consume the wrapper. Examples:

- monitor layout and output selection
- laptop versus desktop defaults
- GPU, display server, or hardware capability switches
- host tags such as `role = "workstation"` or `location = "office"`
- paths to host-specific secrets or generated files
- per-host package variants

Host-specific wrapper settings should still live with the wrapper definition
when the wrapper owns the generated config. The host module should only inject
the resolved host context when it selects the package for that host.

This keeps the wrapper as the single owner of wrapper settings while avoiding a
global wrapper that guesses which host it belongs to.

## Host-Specific Wrapper Pattern

Declare the base wrapper under `flake.wrappers`. The base wrapper must evaluate
without host arguments because `nix-wrapper-modules` also exports it as a global
package:

```text
packages.<system>.<name>
pkgs.local.<name>
```

Read host-specific context from `config._module.args`, and guard host-specific
settings with `lib.mkIf`.

```nix
{
  flake.wrappers.niri = {
    config,
    lib,
    pkgs,
    wlib,
    ...
  }: let
    fleet = config._module.args.fleet or null;
    moduleSettings = config._module.args.moduleSettings or null;
    hasHostSettings = fleet != null && moduleSettings != null && moduleSettings ? monitors;
  in {
    imports = [wlib.wrapperModules.niri];

    settings = lib.mkIf hasHostSettings (
      let
        scheme = (fleet.base16.scheme pkgs).withHashtag;
        inherit (moduleSettings) monitors;
        outputs = import ./_outputs.nix {inherit monitors;};
      in {
        inherit outputs;
        prefer-no-csd = true;
        hotkey-overlay.skip-at-startup = true;
      }
    );
  };
}
```

Then, in the host system module, extend the global package with host arguments:

```nix
{
  flake.modules.nixos.niri = {
    fleet,
    moduleSettings,
    pkgs,
    self,
    ...
  }: {
    programs.niri = {
      enable = true;
      package = self.wrappers.niri.wrap {
        inherit pkgs;
        _module.args = {
          inherit fleet moduleSettings;
        };
      };
    };
  };
}
```

Use the same pattern for generated files:

```nix
{
  flake.wrappers.noctalia-wrapped = {
    config,
    lib,
    pkgs,
    wlib,
    ...
  }: let
    fleet = config._module.args.fleet or null;
    moduleSettings = config._module.args.moduleSettings or null;
    hasHostSettings = fleet != null && moduleSettings != null && moduleSettings ? monitors;
  in {
    imports = [wlib.modules.default];
    package = pkgs.local.noctalia or pkgs.noctalia;

    env.NOCTALIA_CONFIG_DIR =
      lib.mkIf hasHostSettings (dirOf config.constructFiles.generatedConfig.path);

    constructFiles.generatedConfig = lib.mkIf hasHostSettings {
      relPath = "noctalia-config.toml";
      builder = let
        file = pkgs.replaceVars ./noctalia-config.toml.template {
          inherit (moduleSettings.monitors) main secondary;
          mono = fleet.fonts.mono.name;
          sans = fleet.fonts.sans.name;
        };
      in ''
        ln -s ${lib.escapeShellArg file} "$2"
      '';
    };
  };
}
```

Do not declare optional host arguments directly in the wrapper function
signature:

```nix
# Avoid this.
flake.wrappers.niri = { fleet ? null, moduleSettings ? null, ... }: { };
```

The Nix module system still tries to resolve function parameters from module
arguments. Reading from `config._module.args.<name> or null` keeps the base
global wrapper evaluable and lets host modules inject context later with
`.wrap`.

The split is:

- Wrapper layer: owns generated wrapper settings and generated files.
- Host system module: injects `fleet`, `host`, `user`, or `moduleSettings` and
  assigns the resulting derivation to a system option.
- Module settings: owns host/user/fleet policy values such as monitor names.
