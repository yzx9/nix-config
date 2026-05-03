{ config, lib, ... }:

{
  imports = [
    ./claude-code.nix
    ./codex.nix
    ./hapi.nix
    ./opencode.nix
  ];

  # Secrets
  age.secrets = lib.mkIf config.purpose.dev.enable {
    "llm-api-keys".file = ../../secrets/llm-api-keys.age;
  };

  # Enable gstack when claude-code is enabled
  programs.gstack.enable = config.purpose.dev.enable;
}
