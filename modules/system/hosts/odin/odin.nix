{
  fleet.hosts.odin = {
    system = "x86_64-linux";
    owner = "wendy";
    hostId = "abf835ae";

    tags.role = "desktop";
    moduleNames = ["nvidia"];

    networkInterfaces.eno1 = {
      ipv4 = "192.168.1.162/24";
      ipv6 = "fe80::fa06:591c:fca0:664e/64";
    };

    moduleSettings.monitors = {
      main = "DP-2";
      secondary = "HDMI-A-2";
    };

    preservation = {
      enable = true;
      disk = "nvme0n1";
    };
  };
}
