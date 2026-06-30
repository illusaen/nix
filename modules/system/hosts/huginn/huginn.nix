{
  fleet.hosts.huginn = {
    system = "x86_64-linux";
    owner = "wendy";
    hostId = "d0924987";

    tags.role = "server";

    networkInterfaces.eno1 = {
      ipv4 = "192.168.1.164/24";
      ipv6 = "fe80::fa06:591c:fca0:664e/64";
    };

    preservation = {
      enable = true;
      disk = "nvme0n1";
    };
  };
}
