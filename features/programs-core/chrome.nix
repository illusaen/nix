{
  modules.nixos = {
    programs.google-chrome = {
      enable = true;
      extensions = [
        "aeblfdkhhhdcdjpifhhbdiojplfjncoa" # 1Password
        "ddkjiahejlhfcafbddmgiahcphecmpfh" # Ublock
        "dbepggeogbaibhgnhhndojpepiihcmeb" # Vimium
        "ldgfbffkinooeloadekpmfoklnobpien" # Raindrop
        "nplimhmoanghlebhdiboeellhgmgommi" # Tab Groups
        "cemphncflepgmgfhcdegkbkekifodacd" # Custom CSS
        "hnafhkjheookmokbkpnfpmemlppjdgoi" # Allow Right Click
      ];
      policies = {
        PasswordManagerEnabled = false;
      };
    };

    persistUser.directories = [
      ".config/google-chrome"
    ];
  };
}
