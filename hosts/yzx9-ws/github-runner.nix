{ config, ... }:

{
  age.secrets.nex-runner-pat.file = ../../secrets/nex-runner-pat.age;

  services.github-runners.nex-1 = {
    enable = true;
    url = "https://github.com/yzx9/nex";
    name = "yzx9-ws-nex-1";
    tokenFile = config.age.secrets.nex-runner-pat.path;
    extraLabels = [ "nixos" ];

    extraEnvironment = {
      http_proxy = config.my.proxy.http;
      https_proxy = config.my.proxy.http;
      no_proxy = "127.0.0.1,localhost,::1";
    };
  };
}
