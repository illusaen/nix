# Plain Workflows

These commands are the routine plain entrypoints during the migration. Run them
from the repository root.

## Development Shell

```bash
nix-shell shell.nix
```

The shell provides the plain toolchain: `agenix`, `colmena`, `dix`, `treefmt`,
`statix`, `deadnix`, `nil`, `shellcheck`, and formatter helpers.

## Evaluation And Checks

```bash
bin/check
nix-instantiate --eval --strict --json --expr '
  let api = import ./default.nix;
  in import ./tests/fleet.nix {
    inherit (api.libs) evalFleet featureLib fleetLib resolveFleet serviceLib;
  }
'
nix-build ci.nix -A plain-eval
```

Use these before changing host, fleet, feature, service-routing, or deployment
logic. `bin/check` is the fast migration guard; `plain-eval` is the CI aggregate.

## Formatting

```bash
nix fmt
nix-shell shell.nix --run 'treefmt --fail-on-change --no-cache'
```

`treefmt.toml` is the source of truth for formatting and static Nix checks.
Direnv loads this same plain shell through `.envrc`.

## Deployment

```bash
bin/deploy --plan --on @all
bin/deploy --dry-run --on odin
bin/deploy --build --on odin
bin/deploy --apply --on odin
```

NixOS hosts deploy through `hive.nix` and Colmena. Darwin hosts evaluate through
`darwin.nix`; remote Darwin activation is still an explicit migration gap.

Builds and applies run `dix` automatically for local targets when `dix` is in
`PATH`.

## Cache Builds

```bash
nix-build ci.nix -A nixosConfigurations.odin.config.system.build.toplevel
nix-build --expr '
  let
    api = import ./default.nix;
    configs = api.evalLib.mkNixosConfigurations { inherit (api) fleet; };
  in
    configs.odin.config.services.llama-cpp.package
'
nix-build --expr '
  let
    api = import ./default.nix;
    configs = api.evalLib.mkNixosConfigurations { inherit (api) fleet; };
  in
    configs.odin.config.system.build.toplevel
'
```

These mirror the current plain cache workflow in
`.github/workflows/nix-cache.yml`.

## Secrets

```bash
nix-shell shell.nix --run 'RULES=secrets/secrets.nix agenix -i ~/.config/agenix/wendy.agekey -e secrets/hosts/huginn/pihole-web-password.age'
```

Secret policy lives in `secrets/secrets.nix`; feature modules should consume
decrypted paths from normal agenix NixOS options.
