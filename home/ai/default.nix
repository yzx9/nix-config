{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.purpose.dev;
in
{
  imports = [
    ./claude-code.nix
    ./codex.nix
    ./opencode.nix
    ./paseo.nix
  ];

  # Secrets
  age.secrets = lib.mkIf cfg.enable {
    "llm-api-keys".file = ../../secrets/llm-api-keys.age;
  };

  # Enable gstack when claude-code is enabled
  programs.gstack.enable = cfg.enable;

  home.packages = lib.optionals cfg.enable (
    with pkgs;
    [
      skills
    ]
  );
}
