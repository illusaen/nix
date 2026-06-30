{
  fleet.hosts.odin = {
    system = "x86_64-linux";
    owner = "wendy";
    hostId = "abf835ae";

    tags.role = "desktop";
    ## TODO: add service routing depending on services' host and replica fields
    moduleNames = ["nvidia" "llama-cpp"];

    networkInterfaces.eno1 = {
      ipv4 = "192.168.1.162/24";
      ipv6 = "fe80::fa06:591c:fca0:664e/64";
    };

    preservation = {
      enable = true;
      disk = "nvme0n1";
    };
  };
}
