{
  config,
  pkgs,
  lib,
  ...
}:

let
  hasProxy = !(builtins.isNull config.proxy.httpProxy);
  toYAML = lib.generators.toYAML { };
in
lib.mkIf config.purpose.dev.enable {
  age.secrets."api-keys".file = ../secrets/api-keys.age;

  # Inject api keys in runtime
  home.packages =
    let
      goose-cli = pkgs.writeShellApplication {
        name = "goose";
        runtimeInputs = [ pkgs.goose-cli ];
        text = ''
          declare -A secrets

          while IFS='=' read -r key value; do
            [[ -z "$key" ]] && continue # ignore empty lines
            [[ "$key" == \#* ]] && continue # ignore comments
            secrets["@$key@"]="$value"
          done < "${config.age.secrets."api-keys".path}"

          declare -A mapping=(
            ["GOOGLE_API_KEY"]="@gemini@"
            ["OPENAI_API_KEY"]="@siliconflow@" # siliconflow, openai compatible
            ["OPENROUTER_API_KEY"]="@openrouter@"
          )

          for envVar in "''${!mapping[@]}"; do
            secretKey="''${mapping[$envVar]}"
            if [[ -v secrets[$secretKey] ]]; then
              export "$envVar"="''${secrets[$secretKey]}"
            else
              echo "Warning: key $secretKey not defined in secrets." >&2
            fi
          done

          ${lib.optionalString hasProxy "export HTTPS_PROXY=${config.proxy.httpProxy}"}

          export CONTEXT_FILE_NAMES='["AGENTS.md"]'

          exec goose "$@"
        '';
      };
    in
    [ goose-cli ];

  # goose config file
  xdg.configFile."goose/config.yaml".text = toYAML {
    # Model Configuration
    GOOSE_PROVIDER = "openrouter";
    GOOSE_MODEL = "qwen/qwen3-coder";
    GOOSE_TEMPERATURE = 0.7;

    # siliconflow: Value error, after assistant message, next must be user message
    # GOOSE_PROVIDER = "openai";
    # GOOSE_MODEL = "Qwen/Qwen3-Coder-480B-A35B-Instruct";
    # OPENAI_BASE_PATH = "v1/chat/completions";
    # OPENAI_HOST = "https://api.siliconflow.cn/v1";

    # Planning Configuration
    # GOOSE_PLANNER_PROVIDER = "openai";
    # GOOSE_PLANNER_MODEL = "gpt-5";

    # Tool Configuration
    GOOSE_MODE = "smart_approve";
    GOOSE_TOOLSHIM = true;
    GOOSE_CLI_MIN_PRIORITY = 0.2;

    # Environment Configuration
    extensions = {
      developer = {
        bundled = true;
        enabled = true;
        type = "builtin";
        name = "developer";
        display_name = "Developer Tools";
        timeout = 300;
      };

      computercontroller = {
        enabled = true;
        type = "builtin";
        name = "computercontroller";
        display_name = "Computer Controller";
        description = null;
        timeout = 300;
        bundled = true;
      };
    };
  };
}
