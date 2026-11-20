inputs:

{
  default.imports = [
    ./claude-code-proxy.nix
    ./github-runners
    ./gstack.nix
    ./hermes-agent
  ];

  claude-code-proxy.imports = [ ./claude-code-proxy.nix ];
  github-runners.imports = [ ./github-runners ];
  gstack.imports = [ ./gstack.nix ];
  hermes-agent.imports = [ ./hermes-agent ];
}
