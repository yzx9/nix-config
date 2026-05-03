inputs:

{
  default.imports = [
    ./gstack.nix
    ./hermes-agent
    ./hapi-runner.nix
  ];

  gstack.imports = [ ./gstack.nix ];
  hapi-runner.imports = [ ./hapi-runner.nix ];
  hermes-agent.imports = [ ./hermes-agent ];
}
