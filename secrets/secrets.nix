let
  system_yzx9-mbp = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFJCN9HFXys1Ov8cCFHqpNJ61uVm642fPCVGVXqnw4KP";
  system_yzx9-pie = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKfB7heZylUnZIYNM+7DwETGeYVbzLvD6B0W+pRbbNr4 root@yzx9-pie";
  system_yzx9-rpi5 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEjQ6nQg6e154adDPnYj0bW9uCwE2k3rkWKwO2C18Ath root@yzx9-rpi5";
  system_yzx9-ws = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDxJAOqmvqV1hO39/E7SCzHI3xwqHfhNt4MWXKYYZ12m root@nixos";
  systems = [
    system_yzx9-mbp
    system_yzx9-ws
    system_yzx9-rpi5
    system_yzx9-pie
  ];

  user_cvcd-gpu0 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAS+yrwZT0ojxcrDfzy4c2TvDeLmjxwzpmN1e8LsD62B yzx@cvcd-gpu0";
  user_cvcd-gpu1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHFcwtCHSWorJ9Mmwc9gcX3G+mWDYS4nOScModXUcD05 yzx@cvcd-gpu1";
  user_yzx9-mbp = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH8z6g8A53hF7ATKNIGzbYf/rhSm6z+iyPm2nn7E4bnp yzx9@yzx9-mbp";
  user_yzx9-pie = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPfh2M3yz/T4fdLVtvxzwUoiLv9SC83vbuHViqdAcJ7U yzx9@yzx9-pie";
  user_yzx9-rpi5 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKjkUOWFtgvQTxODKsRaTOBwgIpE/4lTZXSZRM2nKrNE yzx9@yzx9-rpi5";
  user_yzx9-ws = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGN854HSrlbBR4/yB0sRk9Plerh2rKn3ZqCZJULRRB8S yzx9@yzx9-ws";
  users = [
    user_cvcd-gpu0
    user_cvcd-gpu1
    user_yzx9-ws
    user_yzx9-mbp
    user_yzx9-rpi5
    user_yzx9-pie
  ];

  rescue = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH1wXmjC1JYCCj0ONwe2BfAdaZNw/TQUF7T4Rn0xbFLp rescue@yzx9.xyz";

  root = [
    user_yzx9-mbp
    rescue
  ];
  all_keys = systems ++ users;
in
{
  "atuin-sync-address.age".publicKeys = all_keys;
  "atuin-session.age".publicKeys = all_keys;
  "atuin-key.age".publicKeys = all_keys;
  "backup-passphrase.age".publicKeys = all_keys;
  "freshrss-pwd.age".publicKeys = all_keys;
  "frpc.toml.age".publicKeys = all_keys;
  "lab-account.age".publicKeys = all_keys;
  "llm-api-keys.age".publicKeys = all_keys;
  "radicale-auth.age".publicKeys = all_keys;
  "ssh-config.age".publicKeys = all_keys;
  "xray.json.age".publicKeys = all_keys;

  # root only
  "id-auth_root.age".publicKeys = root ++ [ system_yzx9-mbp ];
  "id-git_root.age".publicKeys = root;
  "id-github_root.age".publicKeys = root;
}
