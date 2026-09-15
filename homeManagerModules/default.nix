inputs:

{
  default.imports = [
    ./gstack.nix
    ./hermes-agent
  ];

  gstack.imports = [ ./gstack.nix ];
  hermes-agent.imports = [ ./hermes-agent ];
}
