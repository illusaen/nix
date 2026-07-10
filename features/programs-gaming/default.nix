_: {
  imports = [];

  modules.nixos = _: {
    programs.steam.enable = true;

    persistUser.directories = [
      ".local/share/Steam"
    ];
  };

  modules.darwin = _: {};
}
