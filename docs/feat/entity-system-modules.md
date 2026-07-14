# Entity System Modules

Hosts contribute to final NixOS or Darwin systems by listing feature names in
`fleet/hosts.nix`. The fleet registry is plain Nix data; the resolver turns that
data into platform-specific module imports.

## Host Features

Use `fleet.hosts.<name>.features` when a behavior belongs to a host:

```nix
{
  odin = {
    system = "x86_64-linux";
    owner = "wendy";
    features = [
      "base"
      "boot"
      "desktop-shell"
      "programs-core"
    ];
  };
}
```

For each host, `lib/features.nix` computes the recursive feature closure from
`features/<name>/default.nix` imports. The selected platform controls which
module is imported:

```text
modules.nixos   -> NixOS hosts
modules.darwin  -> Darwin hosts
```

The host platform is derived from `system`:

```text
x86_64-linux    -> nixos
aarch64-linux   -> nixos
aarch64-darwin  -> darwin
```

## Derived Configurations

Normal system outputs are derived from the plain fleet registry:

- `hive.nix` exposes only NixOS hosts for Colmena.
- `darwin.nix` exposes Darwin hosts for nix-darwin.
- `lib/hosts.nix` builds both output classes through the same host module
  resolver.

There is no separate configuration registry and no gen-schema instance layer in
the plain path.

## Feature Imports

A feature can imply other features with its `imports` field:

```nix
{
  imports = [
    "nix-settings"
    "secrets"
    "ssh"
  ];
}
```

If a host enables `"base"`, and `base` imports `"ssh"`, the resolver imports
both features for that host. Cycles and missing features are checked by
`lib/features.nix` and `default.nix`.

`imports` can also include local paths. String entries are feature dependencies;
path entries are feature fragments that are merged into the current feature:

```nix
{
  imports = [
    "ssh"
    ./networking.nix
  ];
}
```

Use path imports for split files that should not become host-selectable feature
names.

## Host Context

Feature modules receive resolved host context through module arguments:

```nix
{
  fleet,
  fleetLib,
  host,
  packageLib,
  sources,
  user,
  ...
}: {
  networking.hostName = host.name;
}
```

Use the injected context when the module needs registry data such as the host
owner, routed services, monitor names, preservation settings, fleet domain, or
fleet theme data.

## Service-Routed Features

Service features are activated by `lib/services.nix` in addition to the host's
declared feature list. A host that is the primary or backup for a service gets
that service's feature and receives `host.services.<name>` metadata.

See `docs/feat/service-routing.md` for the routing rules.

## Future Variants

Installers, ISOs, or other variants should build from a host registry entry plus
small output-specific changes. A future plain `fleet.outputs` layer can model
those variants without splitting normal host identity across multiple sources
of truth.
