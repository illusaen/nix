{
  odin = {
    system = "x86_64-linux";
    owner = "wendy";
    targetHost = "odin.home.arpa";
    hostId = "abf835ae";

    tags = ["desktop" "gpu:nvidia" "feature:creative" "feature:dev" "feature:gaming"];
    features = [
      "base"
      "boot"
      "desktop-shell"
      "programs-core"
      "theming"
      "programs-creative"
      "programs-dev"
      "programs-gaming"
      "nvidia"
      "preservation"
    ];

    networkInterfaces.eno1 = {
      ipv4 = "192.168.1.162/24";
      ipv6 = "fe80::fa06:591c:fca0:664e/64";
    };

    monitors = {
      main = "DP-2";
      secondary = "HDMI-A-2";
    };

    preservation = {
      enable = true;
      disk = "nvme0n1";
    };
  };

  huginn = {
    system = "x86_64-linux";
    owner = "wendy";
    targetHost = "huginn.home.arpa";
    hostId = "d0924987";

    tags = ["server"];
    features = [
      "base"
      "boot"
      "preservation"
    ];

    networkInterfaces.enp1s0 = {
      ipv4 = "192.168.1.161/24";
      ipv6 = "fe80::fa06:591c:fca0:664e/64";
    };

    preservation = {
      enable = true;
      disk = "sda";
    };
  };

  muninn = {
    system = "aarch64-linux";
    owner = "wendy";
    targetHost = "muninn.home.arpa";
    hostId = "f687c689";

    tags = ["server"];
    features = [
      "base"
      "boot"
      "preservation"
    ];

    networkInterfaces.eno1 = {
      ipv4 = "192.168.1.163/24";
    };

    preservation = {
      enable = true;
      disk = "nvme0n1";
    };
  };
}
