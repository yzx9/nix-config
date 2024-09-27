let
  user_yzx9-mbp = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH8z6g8A53hF7ATKNIGzbYf/rhSm6z+iyPm2nn7E4bnp yzx9@yzx9-mbp";
  user_yzx9-ws = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGN854HSrlbBR4/yB0sRk9Plerh2rKn3ZqCZJULRRB8S yzx9@yzx9-ws";
  users = [
    user_yzx9-ws
    user_yzx9-mbp
  ];

  system_yzx9-mbp = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFJCN9HFXys1Ov8cCFHqpNJ61uVm642fPCVGVXqnw4KP";
  system_yzx9-ws = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDxJAOqmvqV1hO39/E7SCzHI3xwqHfhNt4MWXKYYZ12m root@nixos";
  systems = [
    system_yzx9-mbp
    system_yzx9-ws
  ];

  yzx9-mbp = [ user_yzx9-mbp ] ++ [ system_yzx9-mbp ];
  yzx9-ws = [ user_yzx9-ws ] ++ [ system_yzx9-ws ];
in
{
  "ssh-config.age".publicKeys = users;
  "rss-pwd.age".publicKeys = users ++ systems;

  # yzx9-mbp only
  "id-git_yzx9-mbp.age".publicKeys = yzx9-mbp;
  "id-github_yzx9-mbp.age".publicKeys = yzx9-mbp;

  # yzx9-ws only
  "frpc_yzx9-ws.toml.age".publicKeys = yzx9-ws;
  "xray_yzx9-ws.json.age".publicKeys = yzx9-ws;
}
