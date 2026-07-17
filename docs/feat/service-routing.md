# Service Routing

Service instances live in `fleet/services.nix`. Each service declares a
`primary` host and optional `backups` by host name. The plain resolver validates
those names against `fleet.hosts` and derives per-host `host.services`. Feature
resolution then adds routed service feature names to each routed host.

## Routing Model

`lib/services.nix` owns service routing:

- `servicesForHost` selects services where the host is the service `primary` or
  one of its `backups`.
- Each routed service receives `role = "primary"` or `role = "backup"`.
- `routeHosts` extends every host with a `services` list.
- Port conflicts are checked per host and port.

Example service data:

```nix
{
  navidrome = {
    feature = "navidrome";
    primary = "odin";
    backups = [ "huginn" ];
    port = 4533;
  };
}
```

On `odin`, the host context contains a routed service record:

```nix
(serviceLib.requireRoutedService host "navidrome").role == "primary"
```

On `huginn`, the host context contains:

```nix
(serviceLib.requireRoutedService host "navidrome").role == "backup"
```

## Feature Activation

The routed service's `feature` value is appended to the routed host's feature
list. If `feature` is omitted, the service name is used. The feature resolver
then imports the matching platform module from `features/<name>/default.nix`.

Evaluation fails when a routed service references an unknown feature or a
feature without a module for the routed host platform. This keeps service data
and feature implementations from drifting silently.

## Service Modules

Service feature modules read their routed registry entry through the injected
host context:

```nix
{ host, ... }: {
  services.example = {
    enable = true;
    port = host.services.example.port;
  };
}
```

Modules that need primary/backup-specific behavior should branch on
`host.services.<name>.role`.

## Service Secrets

Service features can expose a `serviceSecrets` function. `default.nix` asks the
feature resolver for all routed service secret requirements and checks that the
encrypted files are declared and that recipients cover the routed hosts.

This keeps service-owned secrets colocated with the feature metadata instead of
hard-coding service names in top-level checks.
