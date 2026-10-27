inputs:

{
  default.imports = [
    ./claude-code-proxy.nix
    ./gstack.nix
    ./hermes-agent
  ];

  claude-code-proxy.imports = [ ./claude-code-proxy.nix ];
  gstack.imports = [ ./gstack.nix ];
  hermes-agent.imports = [ ./hermes-agent ];
}
