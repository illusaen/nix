# Entity System Modules

Host entities can contribute to the final evaluated NixOS or Darwin system.
This keeps system assembly centralized while allowing host schemas and registry
`extraModules` to attach policy-driven modules.

## Host-Level Module Names

Use `fleet.hosts.<name>.moduleNames` when a module belongs to the host itself.

```nix
{
  fleet.hosts.odin = {
    system = "x86_64-linux";
    owner = "wendy";
    moduleNames = [
      "base"
      "boot"
      "hardware"
    ];
  };
}
```

For NixOS, each name imports matching modules from:

```text
flake.modules.generic.<name>
flake.modules.nixos.<name>
```

For Darwin, each name imports matching modules from:

```text
flake.modules.generic.<name>
flake.modules.darwin.<name>
```

## Derived Configurations

Normal `nixosConfigurations` and `darwinConfigurations` are derived from
`fleet.hosts`. There is no separate normal configuration registry.

```nix
{
  fleet.hosts.odin = {
    system = "x86_64-linux";
    owner = "wendy";
    moduleNames = [ "base" "programs" ];
  };
}
```

The host's `class` determines which output set receives the host. It defaults
from `system`:

```text
x86_64-linux    -> nixosConfigurations
aarch64-linux   -> nixosConfigurations
aarch64-darwin  -> darwinConfigurations
```

Set `fleet.hosts.<name>.class` explicitly only when the default is not enough.

## Recursive Module Imports

Use `flake.moduleImports` to say that one named module implies other named
modules.

```nix
{
  flake.moduleImports.base = [
    "nix-settings"
    "fonts"
    "state-version"
    "security"
  ];
}
```

If a NixOS host imports `"base"`, the system configuration imports generic
`base`, NixOS `base`, then recursively activates `nix-settings`, `fonts`,
`state-version`, and `security`. For each active name, the configuration imports
the generic module and the host-class module when those entries exist.

## Host Extra Modules

Use `fleet.hosts.<name>.extraModule` for host-owned ad-hoc system config.

```nix
{
  fleet.hosts.odin.extraModule = {
    networking.hostId = "abf835ae";
  };
}
```

Keep reusable behavior in named modules when possible. Use host `extraModule`
for host facts and small one-off configuration.

## Schema and extraModules

Entity schemas define options, and registry `extraModules` can compute defaults
for those options.

For example, a registry-level rule can attach a module to every workstation:

```nix
schema.fleet.options.hosts = genSchema.mkInstanceRegistry config.schema.host {
  extraModules = [
    ({ config, lib, ... }: {
      moduleNames = lib.mkIf (config.tags.role or null == "workstation") [
        "desktop-shell"
        "programs"
      ];
    })
  ];
};
```

Those schema contributions remain entity data. The system configuration layer
is still responsible for turning the host's `moduleNames` and `extraModule`
into final NixOS/Darwin imports.

## Fleet Singleton

`fleet` is a singleton gen-schema instance rather than a plain submodule. It
uses the `schema.fleet` kind and is evaluated as the single instance named
`fleet`.

The entity kinds stay separate:

```text
schema.host
schema.user
schema.group
schema.fleet
```

The registries live inside the fleet schema:

```nix
schema.fleet.options.hosts = genSchema.mkInstanceRegistry config.schema.host { };
schema.fleet.options.users = genSchema.mkInstanceRegistry config.schema.user { };
schema.fleet.options.groups = genSchema.mkInstanceRegistry config.schema.group { };
```

This keeps `fleet.hosts`, `fleet.users`, and `fleet.groups` at the same call
sites while making those registries visible through `schema.fleet.options`.
Fleet also receives normal instance fields such as `name` and `id_hash`, and
`schema.fleet.validators` run against the singleton fleet instance.

## Complete Example

```nix
{
  flake.modules.generic.nix-settings = {
    nix.settings.warn-dirty = false;
  };

  fleet.hosts.odin = {
    system = "x86_64-linux";
    owner = "wendy";
    moduleNames = [ "base" "programs" ];
    extraModule.networking.domain = "lan";
  };
}
```

The evaluated NixOS system for `odin` imports the host module names, injects
the host, owner, fleet, and self context, and applies the host extra module.

## Variants and Outputs

Installers, ISOs, or other variants should build from a host registry instance
plus small output-specific changes. A future `fleet.outputs` layer can model
those variants without making normal host configurations split across two
sources of truth.

For example, a future ISO output could point at `fleet.hosts.odin` and add an
`iso` module name or tag-driven module, while the canonical host identity,
owner, system, host facts, and default module stack stay in the host registry.
