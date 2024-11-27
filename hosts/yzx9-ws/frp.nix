{ config, ... }:

{
  imports = [ ../../packages/frpc/option.nix ];

  age.secrets.frpc_yzx9-ws.file = ../../secrets/frpc_yzx9-ws.toml.age;

  services.frpc = {
    enable = true;
    configFile = config.age.secrets.frpc_yzx9-ws.path;
  };
}
