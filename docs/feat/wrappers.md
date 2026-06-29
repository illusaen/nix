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

Today, prefer system modules or `moduleSettings` for this behavior. For
example, host-specific monitor policy can live in `fleet.hosts.<name>` or
resolved host `moduleSettings`, and the NixOS or Darwin module can use that
resolved host context when installing or configuring the service.

## Host-Scoped Wrapper Layer Plan

A future host-scoped wrapper layer should be separate from global
`self.wrappers`.

The shape could be:

```nix
{
  fleet.hosts.odin.wrappers.waybar = { host, fleet, moduleSettings, pkgs, ... }: {
    imports = [ ./wrappers/waybar/module.nix ];
    monitors = host.monitors.conn;
    font.size = moduleSettings.desktop-shell.waybar.fontSize;
  };
}
```

The system configuration builder would then evaluate those host wrapper modules
while building `nixosConfigurations.<host>` or `darwinConfigurations.<host>`.
Its special args should include:

```nix
{
  inherit fleet host user moduleSettings;
}
```

The evaluated derivations should be exposed only inside the host configuration,
for example by adding them to `environment.systemPackages` or by passing them to
host system modules. They should not be merged into global `self.wrappers`,
because global flake outputs cannot represent multiple host-specific variants
under the same wrapper name.

For monitor-aware wrappers like Waybar, the long-term split should be:

- Fleet wrapper layer: fonts, colors, and global defaults.
- Host wrapper layer: monitor connectors, output placement, and per-host panel
  behavior.
- System module layer: installation, service wiring, and host-specific enablement.

This keeps global wrapper derivations reusable while still allowing host-aware
derivations when a wrapper truly needs host context.
