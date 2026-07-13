# Wrappers

Status: this document describes the legacy flake wrapper model. Wrapper parity
is still an open plain-Nix migration item; keep using this as a porting
reference until a plain wrapper API replaces or intentionally drops these
definitions.

This repo uses `nix-wrapper-modules` for portable wrapper derivations. There
is one wrapper declaration path: the upstream `flake.wrappers` shape.

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

Keeping the normal path matters because wrappers are global package definitions.
They should not depend on host or fleet context when they only describe the
program, files, flags, environment variables, or generated config for a wrapper
derivation.

Runtime-selected theme wrappers should usually stay on `flake.wrappers`. If the
wrapper only points at `$XDG_STATE_HOME/nix-theme/current` with an environment
variable or flag, it does not need fleet context. The theme profile generator
owns the fleet-derived colors, fonts, and app config instead.

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
    monitors = config._module.args.monitors or null;
    hasHostSettings = fleet != null && monitors != null && monitors.main != null;
  in {
    imports = [wlib.wrapperModules.niri];

    settings = lib.mkIf hasHostSettings (
      let
        scheme = (fleet.base16.scheme pkgs).withHashtag;
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
    host,
    pkgs,
    self,
    ...
  }: {
    programs.niri = {
      enable = true;
      package = self.wrappers.niri.wrap {
        inherit pkgs;
        _module.args = {
          inherit fleet;
          inherit (host) monitors;
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
    monitors = config._module.args.monitors or null;
    hasHostSettings = fleet != null && monitors != null && monitors.main != null;
  in {
    imports = [wlib.modules.default];
    package = pkgs.local.noctalia or pkgs.noctalia;

    env.NOCTALIA_CONFIG_HOME = lib.mkIf hasHostSettings {
      data = "''${XDG_STATE_HOME:-$HOME/.local/state}/nix-theme/current";
      esc-fn = wlib.escapeShellArgWithEnv;
    };

    constructFiles.generatedConfig = lib.mkIf hasHostSettings {
      relPath = "noctalia/config.toml";
      builder = let
        file = pkgs.replaceVars ./noctalia-config.toml.template {
          inherit (monitors) main secondary;
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
flake.wrappers.niri = { fleet ? null, monitors ? null, ... }: { };
```

The Nix module system still tries to resolve function parameters from module
arguments. Reading from `config._module.args.<name> or null` keeps the base
global wrapper evaluable and lets host modules inject context later with
`.wrap`.

The split is:

- Wrapper layer: owns generated wrapper settings and generated files.
- Host system module: injects `fleet`, `host`, `user`, or narrowed host data and
  assigns the resulting derivation to a system option.
- Host schema and normal NixOS options own host-specific values such as monitor
  names.
