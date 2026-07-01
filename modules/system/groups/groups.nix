{
  fleet.groups = {
    wheel = {
      isPosix = true;
      members = ["system-access"];
    };
    networkmanager = {
      isPosix = true;
      members = ["system-access"];
    };
    tty = {
      isPosix = true;
      members = ["system-access"];
    };
    kvm = {
      isPosix = true;
      members = ["system-access"];
    };
    system-access = {};
  };
}
