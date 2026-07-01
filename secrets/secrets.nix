let
  readPublicKey = path: builtins.replaceStrings ["\n"] [""] (builtins.readFile path);

  optionalPublicKey = path:
    if builtins.pathExists path
    then [(readPublicKey path)]
    else [];

  admins = optionalPublicKey ./users/wendy/age.pub;

  hosts = {
    huginn = readPublicKey ./hosts/huginn/host_ed25519.pub;
    muninn = readPublicKey ./hosts/muninn/host_ed25519.pub;
    odin = readPublicKey ./hosts/odin/host_ed25519.pub;
  };
in {
  "hosts/huginn/pihole-web-password.age".publicKeys = admins ++ [hosts.huginn];
  "shared/navidrome-env.age".publicKeys = admins ++ [hosts.odin hosts.huginn];
}
