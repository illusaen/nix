{
  llama-cpp = {
    feature = "llama-cpp";
    primary = "odin";
    port = 8080;
    protocol = "http";
  };

  navidrome = {
    feature = "navidrome";
    primary = "huginn";
    port = 4533;
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
