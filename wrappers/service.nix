{
  wlib,
  lib,
  config,
  ...
} @ top: let
  topConfig = top.config;
  inherit (builtins) isList;

  renderValue = value:
    if true == value
    then "true"
    else if false == value
    then "false"
    else toString value;

  renderEntry = name: value:
    if value == null
    then []
    else if isList value
    then map (item: "${name}=${renderValue item}") value
    else ["${name}=${renderValue value}"];

  renderSection = name: attrs: let
    lines =
      lib.concatLists
      (lib.mapAttrsToList renderEntry (lib.filterAttrs (_: value: value != null && value != [] && value != {}) attrs));
  in
    lib.optionalString (lines != []) ''
      [${name}]
      ${lib.concatStringsSep "\n" lines}
    '';

  serviceUnitText = let
    inherit (topConfig) service;
  in
    lib.concatStringsSep "\n" [
      (renderSection "Unit" {
        Description = service.description;
        PartOf = service.partOf;
        Requires = service.requires;
        After = service.after;
      })
      (renderSection "Service" service.serviceConfig)
      (renderSection "Install" {
        WantedBy = service.wantedBy;
      })
    ];
in {
  imports = [wlib.modules.constructFiles];

  options.service = lib.mkOption {
    type = lib.types.submodule (
      {config, ...}: {
        options = {
          enable = lib.mkEnableOption "generated user service";
          serviceName = lib.mkOption {
            type = lib.types.str;
            default = topConfig.binName;
            description = "Base service name, without the `.service` suffix.";
          };
          name = lib.mkOption {
            type = lib.types.str;
            default = "${config.serviceName}.service";
            description = "Generated service file name.";
          };
          description = lib.mkOption {
            type = lib.types.str;
            default = "Start ${config.serviceName}";
            description = "Systemd unit description.";
          };
          wantedBy = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = ["graphical-session.target"];
            description = "Install targets.";
          };
          partOf = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = ["graphical-session.target"];
            description = "PartOf unit dependencies.";
          };
          requires = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = ["graphical-session-pre.target"];
            description = "Requires unit dependencies.";
          };
          after = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              "graphical-session.target"
              "graphical-session-pre.target"
            ];
            description = "After unit dependencies.";
          };
          executable = lib.mkOption {
            type = lib.types.str;
            default = topConfig.wrapperPaths.placeholder;
            description = "Executable used as the default service ExecStart.";
          };
          serviceConfig = lib.mkOption {
            type = lib.types.attrsOf lib.types.raw;
            default = {};
            description = "Systemd [Service] entries.";
          };
        };

        config.serviceConfig = {
          ExecStart = lib.mkDefault config.executable;
          Restart = lib.mkDefault "on-failure";
          RestartSec = lib.mkDefault 2;
        };
      }
    );
    default = {};
    description = "Systemd user service generated into lib/systemd/user.";
  };

  config = lib.mkIf config.service.enable {
    constructFiles.generatedServiceFile = {
      relPath = "lib/systemd/user/${config.service.name}";
      content = serviceUnitText;
    };
  };
}
