inputs:

{
  default.imports = [
    ./gstack.nix
    ./hermes-agent
    ./paseo.nix
  ];

  gstack.imports = [ ./gstack.nix ];
  hermes-agent.imports = [ ./hermes-agent ];
  paseo.imports = [ ./paseo.nix ];
}
