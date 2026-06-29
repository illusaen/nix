# Feature Settings

This repo has a settings pipeline for fleet, host, and user entities. The design
is adapted from Sini's feature settings plan and the denix settings graph, but
fits this repo's `flake.modules.{generic,nixos,darwin}` model.

## Model

Settings have two parts:

- `flake.moduleSettings.<class>.<name>` declares typed settings for a named
  flake module.
- `fleet.settings`, `fleet.hosts.<name>.settings`, and
  `fleet.users.<name>.settings` declare raw values.

Only settings for named flake modules in a host's recursive
`moduleNames` closure are considered. Arbitrary ad-hoc modules imported through
`extraModule` may read resolved settings, but their own settings declarations do
not affect the schema unless they are represented in `flake.moduleSettings`.

For a NixOS host, each module name activates matching generic and NixOS
modules. For a Darwin host, each module name activates matching generic and
Darwin modules.

```nix
fleet.hosts.odin.moduleNames = [ "base" "programs" ];
```

The recursive closure is driven by:

```nix
flake.moduleImports.generic.base = [ "nix-settings" ];
flake.moduleImports.nixos.base = [ "state-version" ];
```

## Declarations

Declare settings under the module's name:

```nix
{ lib, ... }: {
  flake.moduleSettings.generic.nix-settings = {
    warnDirty = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };
}
```

Consumers read resolved settings from the injected entity or from the
`settings` special arg:

```nix
{ settings, ... }: {
  nix.settings.warn-dirty = settings.nix-settings.warnDirty;
}
```

System configuration evaluation sets `settings` to the host-effective settings.
The injected `user.settings` field still contains user-effective settings for
modules that explicitly need user scope.

## Entity Schemas

Entity schemas define the raw data model. They do not directly build
`nixosConfigurations` or `darwinConfigurations`.

Current schema responsibilities:

- `schema.host.options.settings` accepts host-authored raw setting values.
- `schema.user.options.settings` accepts user-authored raw setting values.
- `fleet.settings` accepts fleet-authored raw setting values.
- `schema.host.imports` and `schema.user.imports` define computed entity
  fields, such as `host.ipv4`, `host.secretPath`, `host.publicKey`,
  `user.secretPath`, and `user.resolvedGroups`.
- `genSchema.mkInstanceRegistry ... extraModules` wires registry-level computed
  defaults into each entity instance.

The important distinction is raw versus resolved:

- Raw entity settings are stored in the evaluated fleet registry.
- Resolved entity settings are created later by the system configuration layer
  after it knows the active `moduleNames` closure for a host.

This means schema `extraModules` may contribute raw settings defaults, but they
should not try to resolve settings. Resolving settings requires knowing whether
the final system is NixOS or Darwin and which named modules are active.

Example schema-level contribution:

```nix
options.fleet.hosts = genSchema.mkInstanceRegistry config.schema.host {
  extraModules = [
    ({ config, lib, ... }: {
      settings.nix-settings.warnDirty = lib.mkDefault false;
    })
  ];
};
```

That value remains a raw host-layer setting. It is validated and merged only
when a concrete host-derived `nixosConfigurations.<name>` or
`darwinConfigurations.<name>` is evaluated.

## Architecture Plan

The architecture should keep four stages separate.

1. **Entity declaration**
   Data modules populate `fleet`, `fleet.hosts`, `fleet.users`, and
   `fleet.groups`. Entity schemas and registry `extraModules` add computed
   fields and raw defaults.

2. **Host selection**
   `fleet.hosts.<name>` selects its system class, reusable modules, settings,
   owner, and host-specific extra module.

3. **Context preparation**
   The system configuration layer resolves the recursive named module closure,
   imports matching generic plus platform modules, builds the active settings
   schema from `flake.moduleSettings`, resolves fleet/host/user settings, and
   injects resolved `fleet`, `host`, `user`, `settings`, and
   `settingsProvenance`.

4. **System evaluation**
   `lib.nixosSystem` or `inputs.darwin.lib.darwinSystem` evaluates the final
   module list. Normal feature modules consume resolved entity fields and
   settings through module arguments.

Schema contributes to final system evaluation through explicit pipeline hooks
rather than by directly mutating system modules from the schema layer. Hosts can
contribute named modules and ad-hoc modules:

```nix
schema.host.options.moduleNames = lib.mkOption {
  type = lib.types.listOf lib.types.str;
  default = [];
};

schema.host.options.extraModule = lib.mkOption {
  type = lib.types.deferredModule;
  default = {};
};
```

This lets entity schemas and registry `extraModules` attach batteries or
policy-driven modules to a host while keeping the final NixOS/Darwin assembly
centralized in one place.

Recommended direction:

- Let schemas define entity shape and raw defaults.
- Let registry `extraModules` compute entity-local defaults from root paths,
  refs, groups, tags, or policy.
- Let host/user entities expose desired named modules and optional extra
  modules as data.
- Let the system configuration layer remain the only place that converts
  entity data into final evaluated NixOS/Darwin modules.
- Keep settings schema selection tied to the final active named module closure,
  not to all declared flake modules and not to arbitrary ad-hoc `extraModule`
  imports.

## Precedence

Values are resolved with the Nix module system, so normal option typing and
override semantics apply.

Precedence is:

1. Module option defaults.
2. `fleet.settings`.
3. `fleet.hosts.<name>.settings`.
4. `fleet.users.<name>.settings`.
5. Any `lib.mkForce` value wins over normal values at any entity level.

The resolved injected entities are:

- `fleet.settings`: defaults plus fleet values.
- `host.settings`: defaults plus fleet and host values.
- `user.settings`: defaults plus fleet, host, and user values.

## Provenance

`settingsProvenance` is injected as a best-effort source map with the same
shape as resolved settings:

```nix
settingsProvenance.host.nix-settings.warnDirty
```

Source values are `default`, `fleet`, `host`, or `user`. This is useful for
debugging simple scalar settings.

Limitations:

- Complex merges can make a final value come from multiple sources.
- List concatenation and nested attrset merges may not have one precise source.
- `lib.mkForce` changes effective priority; provenance is still best-effort and
  should be treated as diagnostic information, not as a formal proof.

## Findings From References

Sini's feature settings plan uses typed per-feature settings declarations and
`lib.evalModules` for native Nix option merging. The important lesson is to
avoid manual coalescing and let the module system handle defaults, types, and
override priority.

denix builds a settings graph over scope nodes such as fleet/environment, host,
and user. Its key useful ideas are resolved entity settings, source/provenance
queries, and a strict separation between settings declarations and authored
values.

This repo differs from denix because there is no aspect tree. The closest
stable identity is the named flake module registry. That is why settings are
attached to `flake.moduleSettings.<class>.<name>` and filtered by the recursive
`moduleNames` closure.

## Possible Issues

Arbitrary module values do not preserve their original registry name after they
are imported. Use `moduleNames` and `flake.moduleImports` for reusable modules
that should contribute settings declarations.

The option name `imports` is special in Nix modules. Configuration-level named
imports therefore use `moduleNames` instead of an option literally named
`imports`.

Inactive settings declarations are intentionally ignored. If raw entity
settings mention an inactive module namespace, evaluation should fail because no
option declaration exists for that namespace in the active schema.

Dynamic settings schemas can recurse if they force full configuration values too
early. The implementation builds schemas only from `flake.moduleSettings` and
the active name closure, not from evaluated system configuration.
