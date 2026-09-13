# Flake Workflows

These are the routine entry points for the fleet. Run them from the repository
root. `flake.nix` and `flake.lock` are the only dependency and evaluation
entrypoints.

## Development Shell

```bash
nix develop
```

The shell provides `agenix`, `colmena`, `dix`, `treefmt`, `statix`, `deadnix`,
`nixd`, `shellcheck`, and the repository command helpers. Direnv loads this same
shell through `.envrc`.

## Evaluation And Checks

```bash
nix flake check
nix flake check --no-build
tests
```

`nix flake check` evaluates every conventional output and builds the checks for
the current system. The `fleet` check contains the fleet, feature, service,
configuration, Darwin parity, hive, and local-package assertions. The
`runtime-themes` check builds every configured theme profile and exercises an
isolated theme switch. The `formatting` check runs the repository's treefmt
configuration.

New files must be added to Git before evaluating the repository as a Git flake.
Use `path:.` only when intentionally testing untracked files and when the
working tree contains no sensitive ignored files.

## Formatting

```bash
nix fmt
nix fmt -- --fail-on-change
```

`treefmt.toml` remains the source of truth for formatting and static checks.

## Inputs

Dependencies are declared as native inputs in `flake.nix`. Modules and packages
are consumed through their exported flake outputs, and compatible inputs follow
the root `nixpkgs` to keep the lock graph consistent. The only non-flake source
is base16's internal `fromYaml` dependency.

## Packages And Systems

```bash
nix build .#mactahoe-cursors
nix build .#niri-scripts
nix build .#bambu-studio
nix build .#llama-cpp-cuda
nix build .#system-odin
nix build .#system-huginn
nix eval --json .#lib.supportedSystems
```

Local packages are exposed on Linux. Each NixOS host is also exposed as
`system-HOST` on the system matching that host, making cache jobs explicit and
easy to reproduce locally. `lib/supported-systems.nix` is the single source of
truth for fleet system validation and per-system flake outputs.

## Deployment

```bash
bin/deploy --plan --on @all
bin/deploy --dry-run --on odin
bin/deploy --build --on odin
bin/deploy --apply --on odin
```

NixOS hosts deploy through the flake's `colmenaHive`. Darwin hosts build from
`darwinConfigurations`. Builds and applies run `dix` automatically for local
targets when it is available.

## Updating Inputs

Update a single locked input deliberately, then run the full checks:

```bash
nix flake update nixpkgs
nix flake check
```

Avoid combining input updates with changes to fleet or feature behavior.

## Secrets

Do not load credentials from a plaintext `.env`. Inject them for a single
command from a secret manager or an already-established shell environment.

```bash
RULES=secrets/secrets.nix nix develop -c agenix \
  -i "$HOME/.config/agenix/wendy.agekey" \
  -e secrets/hosts/huginn/pihole-web-password.age
```

Secret policy remains in `secrets/secrets.nix`; feature modules consume
decrypted paths through the normal agenix module options.
