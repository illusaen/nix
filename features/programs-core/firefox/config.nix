{pkgs}: {
  extensions = with pkgs.firefox-addons; [
    ublock-origin
    sponsorblock
    onepassword-password-manager
    vimium
    translate-web-pages
    sidebery
  ];
  userChrome = ''
    #TabsToolbar {
      display: none !important;
    }
  '';
  searchEngines = [
    {
      Name = "NixOS Packages";
      URLTemplate = "https://search.nixos.org/packages?type=packages&channel=unstable&query={searchTerms}";
      Method = "GET";
      IconURL = "https://wiki.nixos.org/nixos.png";
      Alias = "@np";
      Description = "NixOS packages";
    }
    {
      Name = "NixOS Options";
      URLTemplate = "https://search.nixos.org/options?type=options&channel=unstable&query={searchTerms}";
      Method = "GET";
      IconURL = "https://wiki.nixos.org/nixos.png";
      Alias = "@no";
      Description = "NixOS options";
    }
    {
      Name = "NixOS Wiki";
      URLTemplate = "https://wiki.nixos.org/w/index.php?search={searchTerms}";
      Method = "GET";
      IconURL = "https://wiki.nixos.org/nixos.png";
      Alias = "@nw";
      Description = "Official NixOS wiki";
    }
    {
      Name = "Noogle";
      URLTemplate = "https://noogle.dev/q/?term={searchTerms}";
      Method = "GET";
      IconURL = "https://wiki.nixos.org/nixos.png";
      Alias = "@noog";
      Description = "Wiki for nix functions";
    }
  ];
}
