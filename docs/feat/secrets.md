# Secrets

## Decision

Use plain `agenix` for the first secrets implementation.

This repository already tracks host SSH public keys in
`secrets/hosts/<host>/host_ed25519.pub` and exposes that path through the host
registry as `host.publicKey`. `agenix` uses age-encrypted files and decrypts
them on the target host during activation, which keeps the model close to the
existing host registry without adding a second metadata system.

## Tool Comparison

| Tool | Fit | Notes |
| --- | --- | --- |
| `agenix` | Recommended | Small surface area, uses existing SSH host keys, secrets decrypt on host activation. |
| `agenix-rekey` | Later | Useful for generated secrets, master keys, YubiKeys, and larger secret sets, but adds rekey storage and extra flake outputs. |
| `sops-nix` | Not v1 | Excellent for structured YAML/JSON/env secrets and team/KMS workflows, but requires `.sops.yaml` and more policy machinery. |

The simpler rule is: use `agenix` while secrets are mostly host or service files;
revisit `agenix-rekey` when secret rotation or generation becomes painful.

## Repository Layout

Secrets policy lives in `secrets/secrets.nix`.

Suggested encrypted file locations:

- `secrets/hosts/<host>/*.age` for host-only secrets.
- `secrets/services/<service>/*.age` for service-owned secrets.
- `secrets/shared/*.age` for secrets intentionally shared by multiple hosts.

Public recipients:

- Host recipients use `secrets/hosts/<host>/host_ed25519.pub`.
- Admin recipients should be stored as public age keys, for example
  `secrets/users/wendy/age.pub`.
- Private admin age keys stay outside the repository.

## Examples

Create an admin age identity:

```bash
age-keygen -o ~/.config/agenix/wendy.agekey
age-keygen -y ~/.config/agenix/wendy.agekey > secrets/users/wendy/age.pub
```

Edit a host secret:

```bash
RULES=secrets/secrets.nix nix run github:ryantm/agenix -- -i ~/.config/agenix/wendy.agekey -e secrets/hosts/huginn/pihole-web-password.age
```

Declare the secret in a NixOS module:

```nix
{
  config,
  ...
}: {
  age.secrets."pihole-web-password" = {
    file = ../../../../secrets/hosts/huginn/pihole-web-password.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };

  # Use config.age.secrets."pihole-web-password".path in the service module.
}
```

Share a secret between hosts by adding both host public keys in
`secrets/secrets.nix`:

```nix
"shared/navidrome-env.age".publicKeys = admins ++ [hosts.odin hosts.huginn];
```

## Colmena

Use agenix secrets as normal NixOS configuration with Colmena. Do not use
Colmena `deployment.keys` for application secrets by default.

Colmena should build, copy, and activate the host configuration. During
activation, `agenix` decrypts secrets on the target host using
`/etc/ssh/host_ed25519`.

Bootstrap flow for a new host:

1. Install or provision the host SSH key.
2. Commit `secrets/hosts/<host>/host_ed25519.pub`.
3. Add the host as a recipient in `secrets/secrets.nix`.
4. Re-encrypt affected secrets with `agenix`.
5. Run the future Colmena deployment for that host.

If `agenix-rekey` is adopted later, its Colmena integration should be planned
around hive introspection so rekeying sees the same host graph that Colmena
deploys.

## Sources

- <https://github.com/ryantm/agenix>
- <https://github.com/oddlama/agenix-rekey>
- <https://github.com/Mic92/sops-nix>
- <https://colmena.cli.rs/unstable/features/keys.html>
- <https://colmena.cli.rs/unstable/reference/deployment.html>
