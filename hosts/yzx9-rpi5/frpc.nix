{ config, ... }:

{
  age.secrets.frpc.file = ../../secrets/frpc.toml.age;

  services.frpc = {
    enable = true;
    configFile = config.age.secrets.frpc.path;
  };

  systemd.services.frpc.restartTriggers = [
    "${config.age.secrets.frpc.file}"
  ];
}
