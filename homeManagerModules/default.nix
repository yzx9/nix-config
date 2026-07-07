inputs:

{
  default.imports = [
    ./gstack.nix
    ./hermes-agent
    ./worktrunk.nix
  ];

  gstack.imports = [ ./gstack.nix ];
  hermes-agent.imports = [ ./hermes-agent ];
  worktrunk.imports = [ ./worktrunk.nix ];
}
