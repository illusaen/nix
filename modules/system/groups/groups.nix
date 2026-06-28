{
  fleet.groups = {
    wheel = {
      gid = 1;
      isPosix = true;
      members = ["system-access"];
    };
    networkmanager = {
      gid = 57;
      isPosix = true;
      members = ["system-access"];
    };
    tty = {
      gid = 3;
      isPosix = true;
      members = ["system-access"];
    };
    kvm = {
      gid = 302;
      isPosix = true;
      members = ["system-access"];
    };
    system-access = {gid = 951;};
  };
}
