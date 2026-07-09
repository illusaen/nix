## fleet

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| base16 | submodule | — |  |
| domain | str | — | Base domain for the fleet |
| fonts | submodule | — |  |
| groups | attrsOf | {} | group instances |
| hosts | attrsOf | {} | host instances |
| moduleSettings | attrsOf | {} | Fleet-level raw module settings defaults. |
| services | attrsOf | {} | service instances |
| themes | submodule | — |  |
| theming | submodule | — |  |
| timeZone | str | CST | Default timezone for the fleet |
| users | attrsOf | {} | user instances |
| wallpaper | submodule | — |  |

## group

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| isPosix | bool | false | If the group maps to an existing POSIX system group |
| members | listOf | \[ ... \] | User or group names that belong to this group. |

## host

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| class | enum | — | System configuration class used to build this host. |
| extraModule | deferredModule | {} | Ad-hoc module that this host contributes to its system configuration. |
| facter | path | — | Derived path to host facter.json |
| hostId | str | — | Used in networking.hostId for ZFS identification |
| ipv4 | str |  | Primary IPv4 address (derived from first interface with IPs, CIDR stripped) |
| ipv6 | str |  | Primary IPv6 address (derived from first interface with IPs, CIDR stripped) |
| moduleNames | listOf | \[ ... \] | Named flake modules that this host contributes to its system configuration. |
| moduleSettings | attrsOf | {} | Host-level raw module settings overrides. |
| monitors | submodule | {} | Host monitor connectors. |
| networkInterfaces | attrsOf | {} | Network interfaces |
| owner | ref(user) | — | Primary user for this host |
| preservation | submodule | — |  |
| privateKey | path | /etc/ssh/host_ed25519 | Path to this host's SSH private key. |
| publicKey | path | — | Derived path to this host's SSH public key. |
| system | enum | — | System platform |
| tags | attrsOf | {} | Host tags for organization and feature gates |

## service

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| backups | setOf(ref(host)) | \[ ... \] | Hosts this service also runs on |
| host | ref(host) | — | Host this service runs on |
| port | int | — | Service port number |
| protocol | enum | tcp | Network protocol |

## user

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| groups | listOf | \[ ... \] | List of groups the user belongs to, with names from the group registry |
| identity | submodule | {} | User identity information |
| moduleSettings | attrsOf | {} | User-level raw module settings overrides. |
| resolvedGroups | listOf | \[ ... \] | Computed group names, including groups that directly or transitively include this user |
| system | submodule | — |  |