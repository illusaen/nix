{
  flake.modules.generic.shell-utils = {pkgs, ...}: {environment.systemPackages = [pkgs.local.git];};

  flake.wrappers.git = {
    wlib,
    pkgs,
    ...
  }: let
    sshKeyPath = "/etc/ssh/ssh_host_ed25519_key";
    accountName = "illusaen";
    displayName = "Wendy Chen";
    email = "jaewchen@gmail.com";
  in {
    imports = [wlib.wrapperModules.git];
    runtimePkgs = with pkgs; [difftastic];
    settings = {
      core.sshCommand = "ssh -i ${sshKeyPath}";
      diff.external = "difft --color auto --background dark --display side-by-side";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      user = {
        inherit email;
        name = displayName;
      };
      credential = {
        inherit accountName;
        helper = "gh auth git-credential";
      };
    };
  };
}
