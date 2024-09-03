let
  user_yzx9-mbp = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICW1MNHAlzdhEUlKKFAOInoISB9UoBDZBTkPDpoOeJ7I me@yzx9.xyz";
  users = [ user_yzx9-mbp ];

  system_yzx9-ws = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDxJAOqmvqV1hO39/E7SCzHI3xwqHfhNt4MWXKYYZ12m root@nixos";
  systems = [ system_yzx9-ws ];
in
{
  "frpc-yzx9-ws.toml.age".publicKeys = users ++ [
    system_yzx9-ws
  ];
}
