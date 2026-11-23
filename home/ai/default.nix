{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.my.host.dev.ai;
in
{
  imports = [
    ./claude-code
    ./claude-code-proxy.nix
    ./codex.nix
  ];

  # Secrets
  age.secrets = lib.mkIf cfg.enable {
    "llm-api-keys".file = ../../secrets/llm-api-keys.age;
  };

  programs.gstack.enable = cfg.enable;

  home.packages = lib.optionals cfg.enable (
    with pkgs;
    [
      skills
    ]
  );
}
