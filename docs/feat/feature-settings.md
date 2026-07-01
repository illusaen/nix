# Feature Settings

This repo has a settings pipeline for fleet, host, and user entities. The design
is adapted from Sini's feature settings plan and the denix settings graph, but
fits this repo's `flake.modules.{generic,nixos,darwin}` model.

## Model

Settings have two parts:

- `flake.moduleOptions.<class>.<name>` declares typed settings options for a named
  flake module.
- `fleet.moduleSettings`, `fleet.hosts.<name>.moduleSettings`, and
  `fleet.users.<name>.moduleSettings` declare raw values.

Only settings for named flake modules in a host's recursive
`moduleNames` closure are considered. Arbitrary ad-hoc modules imported through
`extraModule` may read resolved settings, but their own settings declarations do
not affect the schema unless they are represented in `flake.moduleOptions`.

For a NixOS host, each module name activates matching generic and NixOS
modules. For a Darwin host, each module name activates matching generic and
Darwin modules.

```nix
fleet.hosts.odin.moduleNames = [ "base" "programs" ];
```

The recursive closure is driven by:

```nix
flake.moduleImports.base = [ "nix-settings" "state-version" ];
```

## Declarations

Declare settings under the module's name:

```nix
{ lib, ... }: {
  flake.moduleOptions.generic.nix-settings = {
    warnDirty = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };
}
```

Consumers read resolved settings from the injected entity or from the
`moduleSettings` special arg:

```nix
{ moduleSettings, ... }: {
  nix.settings.warn-dirty = moduleSettings.nix-settings.warnDirty;
}
```

System configuration evaluation sets the `moduleSettings` special arg to the
host-effective module settings. The injected `user.moduleSettings` field still
contains user-effective module settings for modules that explicitly need user
scope.

## Entity Schemas

Entity schemas define the raw data model. They do not directly build
`nixosConfigurations` or `darwinConfigurations`.

Current schema responsibilities:

- `schema.host.options.moduleSettings` accepts host-authored raw setting values.
- `schema.user.options.moduleSettings` accepts user-authored raw setting values.
- `schema.fleet.options.moduleSettings` accepts fleet-authored raw setting
  values.
- `schema.fleet.options.hosts`, `schema.fleet.options.users`, and
  `schema.fleet.options.groups` declare the fleet-owned entity registries.
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
schema.fleet.options.hosts = genSchema.mkInstanceRegistry config.schema.host {
  extraModules = [
    ({ config, lib, ... }: {
      moduleSettings.nix-settings.warnDirty = lib.mkDefault false;
    })
  ];
};
```

That value remains a raw host-layer setting. It is validated and merged only
when a concrete host-derived `nixosConfigurations.<name>` or
`darwinConfigurations.<name>` is evaluated.

## Fleet Schema

`fleet` is a singleton gen-schema instance. It is not a registry because there
is only one fleet, but it still uses the same instance machinery as other
entities:

- `schema.fleet.options` declares the fleet data model.
- `options.fleet` evaluates one `schema.fleet` instance named `fleet`.
- `fleet.id_hash` exists for cheap identity comparison.
- `schema.fleet.validators` run against the singleton instance.
- Nested registries such as `hosts`, `users`, and `groups` are declared under
  `schema.fleet.options` for introspection.

The public data shape is unchanged:

```nix
{
  fleet.domain = "lan";
  fleet.hosts.odin.owner = "wendy";
  fleet.users.wendy.groups = [ "kvm" ];
}
```

The schema shape is now:

```nix
{
  schema.fleet.options.hosts = genSchema.mkInstanceRegistry config.schema.host {
    refs.owner = config.fleet.users;
  };

  schema.fleet.options.users = genSchema.mkInstanceRegistry config.schema.user {
    refs.resolvedGroups = config.fleet.groups;
  };
}
```

This is useful because generated docs, tooling, and introspection can start at
`schema.fleet` and discover the whole fleet surface, including nested entity
registries.

## Schema vs Settings

Use schema options for stable entity facts and shared fleet vocabulary. Use
module settings for module-owned behavior knobs.

Put a value in schema when:

- It describes an entity itself, such as `host.system`, `host.owner`,
  `user.identity`, or `fleet.domain`.
- It is shared vocabulary used by multiple modules.
- It should exist regardless of whether a particular named module is active.
- Other schemas, policies, or modules should be able to rely on it.
- It participates in identity, topology, policy, naming, theming, hardware
  facter settings, or fleet-wide design language.

Put a value in module settings when:

- The option belongs to a named module.
- It should only exist when that module is active through `moduleNames`.
- It is a behavior knob for one feature or module.
- It should use the module settings precedence pipeline:
  defaults < fleet < host < user < `lib.mkForce`.
- Inactive module settings should be rejected by the active settings schema.

Fonts are a schema-level concern in this repo. They are fleet-wide design
vocabulary and are consumed by many modules: GTK, Firefox, Waybar, Niri,
Alacritty, Zed, and others. Keep them under `fleet.fonts`:

```nix
{
  fleet.fonts = {
    mono = {
      name = "JetBrainsMono Nerd Font";
      packageName = "jetbrains-mono";
    };
    sans = {
      name = "Inter";
      packageName = "inter";
    };
  };
}
```

Module-specific font behavior belongs in module settings:

```nix
{
  flake.moduleOptions.generic.zed = {
    useFleetFonts = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  fleet.hosts.odin.moduleSettings.zed.useFleetFonts = false;
}
```

In short: schema is the vocabulary of the fleet; module settings are the knobs
on imported modules.

## Architecture Plan

The architecture should keep four stages separate.

1. **Entity declaration**
   Data modules populate `fleet`, `fleet.hosts`, `fleet.users`, and
   `fleet.groups`. `schema.fleet` declares the singleton fleet shape, while
   `schema.host`, `schema.user`, and `schema.group` declare reusable entity
   kinds. Registry `extraModules` add computed fields and raw defaults.

2. **Host selection**
   `fleet.hosts.<name>` selects its system class, reusable modules,
   moduleSettings, owner, and host-specific extra module.

3. **Context preparation**
   The system configuration layer resolves the recursive named module closure,
   imports matching generic plus platform modules, builds the active settings
   schema from `flake.moduleOptions`, resolves fleet/host/user moduleSettings,
   and injects resolved `fleet`, `host`, `user`, `moduleSettings`, and
   `moduleSettingsProvenance`.

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
2. `fleet.moduleSettings`.
3. `fleet.hosts.<name>.moduleSettings`.
4. `fleet.users.<name>.moduleSettings`.
5. Any `lib.mkForce` value wins over normal values at any entity level.

The resolved injected entities are:

- `fleet.moduleSettings`: defaults plus fleet values.
- `host.moduleSettings`: defaults plus fleet and host values.
- `user.moduleSettings`: defaults plus fleet, host, and user values.

## Provenance

`moduleSettingsProvenance` is injected as a best-effort source map with the same
shape as resolved settings:

```nix
moduleSettingsProvenance.host.nix-settings.warnDirty
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
attached to `flake.moduleOptions.<class>.<name>` and filtered by the recursive
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
early. The implementation builds schemas only from `flake.moduleOptions` and
the active name closure, not from evaluated system configuration.
