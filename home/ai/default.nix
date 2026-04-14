{
  imports = [
    ./claude-code.nix
    ./codex.nix
    ./opencode.nix
  ];

  # Secrets
  age.secrets."llm-api-keys".file = ../../secrets/llm-api-keys.age;
}
