{ config, ... }:

{
  imports = [ ../../packages/frpc/option.nix ];

  age.secrets.frpc_yzx9-rpi5.file = ../../secrets/frpc_yzx9-rpi5.toml.age;

  services.frpc = {
    enable = true;
    configFile = config.age.secrets.frpc_yzx9-rpi5.path;
  };
}
