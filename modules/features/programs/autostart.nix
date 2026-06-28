{
  flake.modules.nixos.autostart = {
    lib,
    config,
    ...
  }: let
    mkService = package: {
      wantedBy = ["graphical-session.target"];
      partOf = ["graphical-session.target"];
      after = [
        "graphical-session.target"
      ];
      description = "1Password";
      serviceConfig = {
        ExecStart = "${lib.getExe package}";
        Restart = "on-failure";
      };
    };
    name = package: package.pname or package.name or package.meta.mainProgram or (lib.getName package);
  in {
    options.systemdAutostart = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
    };
    config.systemd.user.services = config.systemdAutostart |> map (p: lib.nameValuePair (name p) (mkService p)) |> builtins.listToAttrs;
  };
}
