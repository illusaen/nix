{
  name = "wendy";
  fullName = "Wendy Chen";
  dirs = {
    projects = "$HOME/projects";
    nix = "$HOME/nix";
  };

  seedbox = rec {
    group = "users";
    hostName = "modi";
    ip = "192.168.4.103";
    gateway = "192.168.4.1";
    domain = "${hostName}.lan";
    hd = {
      misc = "misc";
      hdd = "hdd";
    };
  };
}
