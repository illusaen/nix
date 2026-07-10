{
  llama-cpp = {
    feature = "llama-cpp";
    primary = "odin";
    backups = [];
    port = 8080;
    protocol = "http";
  };

  navidrome = {
    feature = "navidrome";
    primary = "odin";
    backups = [];
    port = 8080;
    protocol = "http";
  };

  pihole = {
    feature = "pihole";
    primary = "huginn";
    backups = ["muninn"];
    port = 53;
    protocol = "tcp";
  };
}
