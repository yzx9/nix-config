inputs:

{
  default.imports = [
    ./hermes-agent
    ./hapi-runner.nix
  ];

  hermes-agent.imports = [ ./hermes-agent ];
  hapi-runner.imports = [ ./hapi-runner.nix ];
}
