* add features:
  - nvf
  - agenix/agenix-rekey/sops
  - networking
  - bambu studio
  - youtube music player
  - services for server
* fix desktop filtering on fuzzel
* make monitors host specific in moduleSettings - fleet can contain the monitor data but the actual monitor each host uses should be monitor-specific.
  * ties into the host-specific wrapped package feature since each package that needs `monitor` should be host-specific
* add theming engine that allows runtime switching of themes
