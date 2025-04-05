let
  system_yzx9-mbp = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFJCN9HFXys1Ov8cCFHqpNJ61uVm642fPCVGVXqnw4KP";
  system_yzx9-pie = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKfB7heZylUnZIYNM+7DwETGeYVbzLvD6B0W+pRbbNr4 root@yzx9-pie";
  system_yzx9-rpi5 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICvd29SPiaKFU1+Rsb+MXHmD3fMzaYfwBckUUAnoZKR7 root@yzx9-rpi5";
  system_yzx9-ws = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDxJAOqmvqV1hO39/E7SCzHI3xwqHfhNt4MWXKYYZ12m root@nixos";

  user_cvcd-gpu1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHFcwtCHSWorJ9Mmwc9gcX3G+mWDYS4nOScModXUcD05 yzx@cvcd-gpu1";
  user_yzx9-mbp = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH8z6g8A53hF7ATKNIGzbYf/rhSm6z+iyPm2nn7E4bnp yzx9@yzx9-mbp";
  user_yzx9-pie = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPfh2M3yz/T4fdLVtvxzwUoiLv9SC83vbuHViqdAcJ7U yzx9@yzx9-pie";
  user_yzx9-rpi5 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM359KKo6BK2OtDCXLhw1zP6g8OE62Hmhf3v0MXcnyYG yzx9@yzx9-rpi5";
  user_yzx9-ws = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGN854HSrlbBR4/yB0sRk9Plerh2rKn3ZqCZJULRRB8S yzx9@yzx9-ws";

  root = [ user_yzx9-mbp ];

  yzx9-rpi5 = root ++ [
    system_yzx9-rpi5
    user_yzx9-rpi5
  ];

  all = root ++ [
    user_cvcd-gpu1
    user_yzx9-ws
    user_yzx9-mbp
    user_yzx9-rpi5
    user_yzx9-pie
    system_yzx9-mbp
    system_yzx9-ws
    system_yzx9-rpi5
    system_yzx9-pie
  ];
in
{
  "api-key-deepseek.age".publicKeys = all;
  "api-key-gemini.age".publicKeys = all;
  "api-key-openrouter.age".publicKeys = all;
  "api-key-siliconflow.age".publicKeys = all;
  "id-lab.pub.age".publicKeys = all;
  "ssh-config.age".publicKeys = all;
  "xray.json.age".publicKeys = all;

  # yzx9-rpi5 only
  "frpc_yzx9-rpi5.toml.age".publicKeys = yzx9-rpi5;
  "rss-pwd.age".publicKeys = yzx9-rpi5;

  # root only
  "id-auth_root.age".publicKeys = root;
  "id-git_root.age".publicKeys = root;
  "id-github_root.age".publicKeys = root;
  "id-lab.age".publicKeys = root;
}
