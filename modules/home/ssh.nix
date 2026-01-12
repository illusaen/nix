{
  lib,
  helpers,
  config,
  ...
}:

with lib;
let
  cfg = config.modules.ssh;

in
{
  options.modules.ssh = {
    enable = helpers.mkTrueOption "ssh";
  };
  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*" = {
          forwardAgent = false;
          addKeysToAgent = "no";
          compression = false;
          serverAliveInterval = 0;
          serverAliveCountMax = 3;
          hashKnownHosts = false;
          userKnownHostsFile = "~/.ssh/known_hosts";
          controlMaster = "no";
          controlPath = "~/.ssh/master-%r@%n:%p";
          controlPersist = "no";
          identityFile = "~/.ssh/id_rsa";
        };

        "github" = {
          hostname = "github.com";
          user = "git";
          identityFile = "~/.ssh/id_rsa";
        };
      };
    };
  };
}
