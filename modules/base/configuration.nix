{
  flake.modules.nixos.base-configuration = {
    lib,
    pkgs,
    ...
  }: {
    # Use the systemd-boot EFI boot loader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # Configure network connections interactively with nmcli or nmtui.
    networking.networkmanager.enable = true;
    networking.hostId = lib.mkDefault "b9443213";
    nixpkgs.config.allowUnfree = true;

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.wendy = {
      isNormalUser = true;
      extraGroups = ["wheel" "networkmanager"]; # Enable ‘sudo’ for the user.
      password = "arst";
      shell = pkgs.zsh;
    };

    programs.firefox.enable = true;

    # List packages installed in system profile.
    # You can use https://search.nixos.org/ to find more packages (and options).
    environment.systemPackages = with pkgs; [
      foot
      _1password-gui-beta
      _1password-cli
      fuzzel
      zed-editor
    ];

    services.openssh.enable = true;
  };
}
