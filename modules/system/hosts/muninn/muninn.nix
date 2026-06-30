{
  # Raspberry Pi 4 Model B+
  fleet.hosts.muninn = {
    system = "aarch64-linux";
    owner = "wendy";
    hostId = "f687c689";

    tags.role = "server";

    networkInterfaces.eno1 = {
      ipv4 = "192.168.1.163/24";
      ipv6 = "fe80::fa06:591c:fca0:664e/64";
    };

    preservation = {
      enable = true;
      disk = "nvme0n1";
    };
  };
}
