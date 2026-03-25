{
  config,
  pkgs,
  ...
}:

let
  skills = import ./skills.nix { inherit pkgs; };

  codex' = pkgs.writeShellApplication {
    name = "codex";
    runtimeInputs = [
      pkgs.yzx9.with-secrets
      pkgs.codex
    ];

    runtimeEnv.HTTPS_PROXY = "http://${config.proxy.httpProxy}";

    text = ''
      with-secrets "${config.age.secrets."llm-api-keys".path}" \
        --allow CONTEXT7_API_KEY \
        -- codex "$@"
    '';
  };
in
{
  programs.codex = {
    enable = config.purpose.dev.enable;
    package = codex';
    inherit skills;

    settings = {
      sandbox_mode = "workspace-write";
      approval_policy = "untrusted";
      allow_login_shell = false;
    };
  };
}
