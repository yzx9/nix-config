inputs:

{
  default.imports = [
    ./gstack.nix
    ./hermes-agent
    ./paseo.nix
    ./worktrunk.nix
  ];

  gstack.imports = [ ./gstack.nix ];
  hermes-agent.imports = [ ./hermes-agent ];
  paseo.imports = [ ./paseo.nix ];
  worktrunk.imports = [ ./worktrunk.nix ];
}
