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

Only settings for named flake modules in a configuration's recursive
`moduleNames` closure are considered. Arbitrary ad-hoc modules imported through
`extraModule` may read resolved settings, but their own settings declarations do
not affect the schema unless they are represented in `flake.moduleSettings`.

For a NixOS configuration, each module name activates matching generic and
NixOS modules. For a Darwin configuration, each module name activates matching
generic and Darwin modules.

```nix
nixos.configurations.odin.moduleNames = [
  "base"
  "programs"
];
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
