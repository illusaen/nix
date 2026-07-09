# Entity Option Audit

This audit compares this repository with the entity and aspect designs in
`illusaen/denix`, `sini/nix-config`, and `denful/den`.

## Summary

The current architecture already uses `moduleNames`, `moduleImports`,
preservation, host ownership, and service routing. The main
gaps were entity metadata that existed in the registries but did not affect the
generated system: host network interfaces, fleet domain/time zone, and POSIX
user/group metadata.

The implementation should stay smaller than the upstream designs for now. Both
`illusaen/denix` and `sini/nix-config` have richer networking schemas with DHCP,
bridges, bonds, MTU, managed interfaces, and wait-online controls. Those are
useful references, but this repository currently only declares static `ipv4`
and `ipv6` addresses, so the first pass wires only that shape into
`systemd-networkd`.

`denful/den` is more of a framework for scoped entity policies and includes. Its
model is useful as a direction for future simplification, but copying it would
add more abstraction than this cleanup needs.

## Host Options

| Option | Status | Use |
| --- | --- | --- |
| `system` | Used | Selects NixOS vs Darwin class and `nixpkgs.hostPlatform`. |
| `class` | Used | Routes each host to `nixosConfigurations` or `darwinConfigurations`. |
| `networkInterfaces` | Used | Generates minimal static `systemd-networkd` networks for NixOS hosts. |
| `ipv4`, `ipv6` | Used | Derived primary addresses for references and validation. |
| `owner` | Used | Selects the host user and validates injected host context. |
| `hostId` | Used | Sets `networking.hostId`. |
| `facter` | Used | Feeds hardware facter configuration. |
| `publicKey` | Used | Points to the tracked host SSH public key used for SSH known hosts and agenix recipients. |
| `tags` | Used | Role tags expand default module names such as desktop or services. |
| `monitors` | Used | Feeds host-specific display and wrapper configuration. |
| `moduleNames` | Used | Declares the named modules enabled by the host. |
| `extraModule` | Used | Adds host-local ad hoc module configuration. |
| `preservation` | Used | Drives preservation and disko behavior. |

Future networking expansion should add fields only when a host needs them:
`dhcp`, `managed`, `mtu`, `requiredForOnline`, bridges, and bonds. Until then,
the smaller schema is faster to evaluate and easier to read.

## User And Group Options

| Option | Status | Use |
| --- | --- | --- |
| `identity.displayName` | Used | Sets the system user description. |
| `identity.accountName` | Reserved | Useful for external account metadata; no system consumer yet. |
| `identity.email` | Reserved | Useful for Git or account metadata; no system consumer yet. |
| `identity.sshKeys` | Used | Populates OpenSSH authorized keys. |
| `groups` | Used | Feeds the registry membership graph. |
| `resolvedGroups` | Used | Registry-resolved group data backs transitive POSIX group membership. |
| `system.uid` | Used | Sets the NixOS user UID. |
| `system.isAdmin` | Used | Adds `wheel` access. |
| `group.isPosix` | Used | Marks groups that map to existing system groups and can be emitted in `extraGroups`. |
| `group.members` | Used | Expands nested group membership into system `extraGroups`. |

The group registry is now the source of truth for access. Hardcoded host user
groups should be avoided because they bypass `fleet.groups`.

## Fleet Options

| Option | Status | Use |
| --- | --- | --- |
| `domain` | Used | Sets the NixOS networking domain. |
| `timeZone` | Used | Sets `time.timeZone`. |

## Cleanup Notes

- Keep `moduleImports` as one logical dependency list keyed by module name.
  Resolution should select the generic module plus the active platform module.
- Keep host public keys as registry metadata; avoid adding secret path metadata
  until there is a direct consumer.
- Prefer direct NixOS/Darwin module generation from entity registries over a
  broad aspect framework. The current code is easier to optimize when registry
  data has a small number of obvious consumers.
