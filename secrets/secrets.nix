let
  user_yzx9-mbp = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH8z6g8A53hF7ATKNIGzbYf/rhSm6z+iyPm2nn7E4bnp yzx9@yzx9-mbp";
  user_yzx9-ws = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGN854HSrlbBR4/yB0sRk9Plerh2rKn3ZqCZJULRRB8S yzx9@yzx9-ws";
  user_yzx9-rpi5 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM359KKo6BK2OtDCXLhw1zP6g8OE62Hmhf3v0MXcnyYG yzx9@yzx9-rpi5";
  user_yzx9-pie = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPfh2M3yz/T4fdLVtvxzwUoiLv9SC83vbuHViqdAcJ7U yzx9@yzx9-pie";
  users = [
    user_yzx9-ws
    user_yzx9-mbp
    user_yzx9-rpi5
    user_yzx9-pie
  ];

  system_yzx9-mbp = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFJCN9HFXys1Ov8cCFHqpNJ61uVm642fPCVGVXqnw4KP";
  system_yzx9-ws = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDxJAOqmvqV1hO39/E7SCzHI3xwqHfhNt4MWXKYYZ12m root@nixos";
  system_yzx9-rpi5 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICvd29SPiaKFU1+Rsb+MXHmD3fMzaYfwBckUUAnoZKR7 root@yzx9-rpi5";
  system_yzx9-pie = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKfB7heZylUnZIYNM+7DwETGeYVbzLvD6B0W+pRbbNr4 root@yzx9-pie";
  systems = [
    system_yzx9-mbp
    system_yzx9-ws
    system_yzx9-rpi5
    system_yzx9-pie
  ];

  yzx9-root = [ user_yzx9-mbp ];
  yzx9-rpi5 = yzx9-root ++ [
    system_yzx9-rpi5
    user_yzx9-rpi5
  ];
in
{
  "id-lab.age".publicKeys = users;
  "id-lab.pub.age".publicKeys = users;
  "ssh-config.age".publicKeys = users;
  "rss-pwd.age".publicKeys = users ++ systems;
  "xray.json.age".publicKeys = users ++ systems;
  "api-key-deepseek.age".publicKeys = users;
  "api-key-gemini.age".publicKeys = users;

  # root only
  "id-git_root.age".publicKeys = yzx9-root;
  "id-github_root.age".publicKeys = yzx9-root;

  # yzx9-rpi5 only
  "frpc_yzx9-rpi5.toml.age".publicKeys = yzx9-rpi5;
}
