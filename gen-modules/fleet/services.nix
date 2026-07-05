{
  fleet.services = {
    llama-cpp = {
      port = 8080;
      protocol = "http";
      host = "odin";
    };
    navidrome = {
      port = 8080;
      protocol = "http";
      host = "odin";
    };
    pihole = {
      host = "huginn";
      backups = ["muninn"];
      port = 53;
    };
  };
}
