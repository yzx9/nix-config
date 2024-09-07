let
  user_yzx9-mbp = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH8z6g8A53hF7ATKNIGzbYf/rhSm6z+iyPm2nn7E4bnp yzx9@yzx9-mbp";
  users = [ user_yzx9-mbp ];

  system_yzx9-mbp = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFJCN9HFXys1Ov8cCFHqpNJ61uVm642fPCVGVXqnw4KP";
  system_yzx9-ws = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDxJAOqmvqV1hO39/E7SCzHI3xwqHfhNt4MWXKYYZ12m root@nixos";
  systems = [
    system_yzx9-mbp
    system_yzx9-ws
  ];
in
{
  # yzx9-mbp only
  "id-git_yzx9-mbp.age".publicKeys = users ++ [ system_yzx9-mbp ];
  "id-github_yzx9-mbp.age".publicKeys = users ++ [ system_yzx9-mbp ];
  "ssh-config_yzx9-mbp.age".publicKeys = users ++ [ system_yzx9-mbp ];

  # yzx9-ws only
  "frpc_yzx9-ws.toml.age".publicKeys = users ++ [ system_yzx9-ws ];
}
