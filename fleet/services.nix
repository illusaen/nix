{
  llama-cpp = {
    primary = "odin";
    port = 8080;
  };

  navidrome = {
    primary = "huginn";
    port = 4533;
  };

  pihole = {
    primary = "huginn";
    backups = ["muninn"];
    port = 53;
  };
}
