{ inputs, vars, ... }:

{
  environment.systemPackages = [
    inputs.agenix.packages.${vars.system}.default
  ];

  age.secrets.frpc-yzx9-ws.file = ../../secrets/frpc-yzx9-ws.toml.age;
}
