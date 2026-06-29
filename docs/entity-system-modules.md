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
  flake.moduleImports.generic.base = [
    "nix-settings"
    "fonts"
  ];

  flake.moduleImports.nixos.base = [
    "state-version"
    "security"
  ];
}
```

If a NixOS host imports `"base"`, the system configuration imports generic
`base`, NixOS `base`, then recursively imports generic `nix-settings`, generic
`fonts`, NixOS `state-version`, and NixOS `security` when those module entries
exist.

The same recursive closure drives settings schema selection. Only named modules
in this active closure can contribute `flake.moduleOptions`.

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
options.fleet.hosts = genSchema.mkInstanceRegistry config.schema.host {
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

## Complete Example

```nix
{
  flake.moduleOptions.generic.nix-settings.warnDirty = lib.mkOption {
    type = lib.types.bool;
    default = false;
  };

  flake.modules.generic.nix-settings = { moduleSettings, ... }: {
    nix.settings.warn-dirty = moduleSettings.nix-settings.warnDirty;
  };

  fleet.moduleSettings.nix-settings.warnDirty = false;

  fleet.hosts.odin = {
    system = "x86_64-linux";
    owner = "wendy";
    moduleNames = [ "base" "programs" ];
    moduleSettings.nix-settings.warnDirty = true;
    extraModule.networking.domain = "lan";
  };
}
```

The evaluated NixOS system for `odin` imports the host module names, resolves
settings for that active closure, and injects the final host settings into
system modules.

## Variants and Outputs

Installers, ISOs, or other variants should build from a host registry instance
plus small output-specific changes. A future `fleet.outputs` layer can model
those variants without making normal host configurations split across two
sources of truth.

For example, a future ISO output could point at `fleet.hosts.odin` and add an
`iso` module name or tag-driven module, while the canonical host identity,
owner, system, moduleSettings, and default module stack stay in the host registry.
