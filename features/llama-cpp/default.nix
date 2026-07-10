{...}: {
  imports = [];

  modules.nixos = {
    host,
    lib,
    pkgs,
    ...
  }: let
    service = host.services.llama-cpp;
    enabled = service.role == "primary" || service.role == "backup";
    iniFormat = pkgs.formats.ini {};
  in {
    config = lib.mkIf enabled {
      assertions = [
        {
          assertion = service.protocol == "http" || service.protocol == "https";
          message = "llama-cpp expects an HTTP transport protocol";
        }
      ];

      environment.systemPackages = [pkgs.llama-cpp];

      services.llama-cpp = {
        enable = true;
        openFirewall = true;
        package = pkgs.llama-cpp;
        settings.host = "0.0.0.0";
        settings.port = service.port;
        settings.models-preset = iniFormat.generate "llama-cpp-models.ini" {
          "*" = {
            context-shift = true;
          };
          "Qwen3.5-9B" = {
            hf-repo = "unsloth/Qwen3.5-9B-GGUF";
            hf-file = "Qwen3.5-9B-UD-Q4_K_XL.gguf";
            alias = "unsloth/Qwen3.5-9B";
            temp = "1.0";
            top-p = "0.95";
            top-k = "20";
            presence-penalty = "1.5";
            repeat-penalty = "1.0";
          };
          "Qwen3-Coder-Next" = {
            hf-repo = "unsloth/Qwen3-Coder-Next-GGUF";
            hf-file = "Qwen3-Coder-Next-UD-IQ2_XXS.gguf";
            alias = "unsloth/Qwen3-Coder-Next";
            temp = "1.0";
            top-p = "0.95";
            top-k = "40";
            presence-penalty = "1.5";
            repeat-penalty = "1.0";
          };
        };
      };
    };
  };
}
