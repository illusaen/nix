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

## Configuration-Level Module Names

Use `nixos.configurations.<name>.moduleNames` or
`darwin.configurations.<name>.moduleNames` for deployment-specific additions.

```nix
{
  nixos.configurations.odin = {
    moduleNames = [
      "desktop-shell"
      "programs"
      "theming"
    ];
  };
}
```

The final named module list is:

```text
host.moduleNames ++ configuration.moduleNames
```

The combined list is deduplicated through the recursive closure logic.

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
in this active closure can contribute `flake.moduleSettings`.

## Host Extra Modules

Use `fleet.hosts.<name>.extraModule` for host-owned ad-hoc system config.

```nix
{
  fleet.hosts.odin.extraModule = {
    networking.hostId = "abf835ae";
  };
}
```

Use `nixos.configurations.<name>.extraModule` or
`darwin.configurations.<name>.extraModule` for configuration-owned ad-hoc
system config.

```nix
{
  nixos.configurations.odin.extraModule = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.local.misc-scripts ];
  };
}
```

The final ad-hoc module order is:

```text
host.extraModule
configuration.extraModule
```

That means configuration-level ad-hoc values can override host-level defaults
with normal Nix module priority.

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
  flake.moduleSettings.generic.nix-settings.warnDirty = lib.mkOption {
    type = lib.types.bool;
    default = false;
  };

  flake.modules.generic.nix-settings = { settings, ... }: {
    nix.settings.warn-dirty = settings.nix-settings.warnDirty;
  };

  fleet.settings.nix-settings.warnDirty = false;

  fleet.hosts.odin = {
    system = "x86_64-linux";
    owner = "wendy";
    moduleNames = [ "base" ];
    settings.nix-settings.warnDirty = true;
  };

  nixos.configurations.odin = {
    moduleNames = [ "programs" ];
    extraModule.networking.domain = "lan";
  };
}
```

The evaluated NixOS system for `odin` imports the host module names plus the
configuration module names, resolves settings for that active closure, and
injects the final host settings into system modules.
