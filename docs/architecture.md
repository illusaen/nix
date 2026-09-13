# Architecture

The repository has one dependency and evaluation entrypoint: `flake.nix`.
Fleet data stays separate from evaluation logic so hosts, services, and users
remain easy to inspect and change.

```text
flake inputs
    |
fleet/*.nix ------> lib/mk-api.nix ------> nixosConfigurations
    |                    |                 darwinConfigurations
    |                    |                 colmenaHive
    |                    `---------------> packages / checks / devShells
    |
    `--> resolved host --> feature modules --> system configuration
             ^
             |
       routed services
```

## Repository Layers

- `fleet/` contains declarative hosts, users, groups, services, fonts, and theme
  profiles.
- `lib/` validates and resolves fleet data, discovers features and packages,
  and builds system and deployment outputs.
- `features/` owns NixOS and Darwin behavior. A feature can use local path
  fragments without turning each file into a globally selectable feature.
- `packages/` contains repository-local packages exposed through the overlay as
  `pkgs.local` and through flake package outputs.
- `tests/` contains pure fleet assertions and buildable integration checks.
- `bin/deploy` is the shared NixOS and Darwin deployment interface.

Dependencies flow inward from `flake.nix`; feature modules consume injected
fleet context but do not import the flake or construct configurations.

## Fleet Resolution

`lib/mk-api.nix` creates the shared API:

1. Evaluate raw `fleet/` data against `lib/fleet-options.nix`.
2. Validate cross-references, uniqueness, addresses, and secret recipients.
3. Route each service to its primary and backup hosts.
4. Derive each host's complete feature list.
5. Build NixOS, Darwin, Colmena, test, and package outputs from that result.

A host's platform is derived from its system. `lib/supported-systems.nix` is
the shared system list for fleet validation and per-system flake outputs.

## Feature Resolution

Top-level directories in `features/` are selectable features. Their
`default.nix` files may provide:

```nix
{
  imports = [./split-module.nix];
  modules = {
    generic = { ... };
    nixos = { ... };
    darwin = { ... };
  };
  tests = { ... };
  serviceSecrets = {hosts, ...}: [ ... ];
}
```

`imports` contains only local path fragments. Fragments are merged into their
parent feature; they do not become host-selectable names.

Features are derived from host data:

- every host receives `base`;
- Linux hosts receive `boot`;
- desktops receive `programs-core` and `theming`;
- Linux desktops also receive `desktop-shell`;
- `gpu:nvidia` enables `nvidia`;
- `feature:NAME` enables `programs-NAME`;
- preservation settings enable `preservation`;
- routed services enable their declared feature.

Use `fleet.hosts.<name>.features` only for behavior that cannot be derived from
those rules.

## Service Routing

Services live in `fleet/services.nix` and declare a primary host, optional
backup hosts, and ports. Resolution adds a list of routed service records to
each affected host. Each record includes its name and a `primary` or `backup`
role.

Feature modules retrieve their record with:

```nix
service = serviceLib.requireRoutedService host "navidrome";
```

The shared checks reject unknown hosts or features, unsupported platform
modules, port conflicts, missing encrypted-secret declarations, and incomplete
secret recipient lists.

## Public Flake Outputs

- `nixosConfigurations` and `darwinConfigurations` contain host systems.
- `colmenaHive` contains NixOS deployment nodes.
- `packages` contains local packages, host systems, and explicit cache targets.
- `checks` contains fleet integration, formatting, and runtime-theme tests.
- `devShells` and `formatter` provide the development workflow.
- `lib` exposes fleet data and the small reusable resolver libraries used by
  `bin/deploy` and inspection commands.

See `feat/flake-workflows.md`, `feat/runtime-theming.md`, and `feat/secrets.md`
for operational details.
