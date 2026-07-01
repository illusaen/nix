# Service Routing

Service instances live in `fleet.services`. Each service declares a primary
`host` and optional `backups`, both as `gen-schema` host references. The system
configuration builder uses those references to decide which host imports each
service module.

## Findings

- `modules/flake/schema/service.nix` defines service metadata: `port`,
  `protocol`, `host`, and `backups`.
- `modules/flake/schema/registry.nix` binds `host` and `backups` refs to
  `fleet.hosts`, so string values such as `"odin"` evaluate to full host
  instances.
- `gen-schema` refs expose stable `id_hash` values for comparing instances.
  Its `setOf` helper deduplicates referenced instances by `id_hash`.
- `sini/nix-config` routes host-scoped behavior through its richer
  aspect/include/policy model. This repo keeps the same intent but implements it
  through the existing named-module closure used by `moduleNames`.

References:

- <https://github.com/sini/gen-schema>
- <https://github.com/sini/nix-config>

## Routing Model

For each host, the system builder derives `host.services` from
`fleet.services`:

- `host.services.<name>` exists when the current host is either the service's
  primary `host` or one of its `backups`.
- Each routed service is extended with `role = "primary"` or
  `role = "backup"`.

The keys of `host.services` are appended to `host.moduleNames` before the
recursive module closure is computed. A service named `llama-cpp` therefore
activates the named module `llama-cpp` on its primary and backup hosts.

## Failure Policy

Routed services must have a matching flake module for the host class. Evaluation
fails if a service is assigned to a host but no `flake.modules.generic.<name>` or
`flake.modules.<class>.<name>` exists.

This keeps the registry and module set from drifting silently. Services that
should not affect host configuration should not be added to `fleet.services`.

## Service Modules

Service modules can read their routed registry entry through the injected host
context:

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
