{
  config,
  pkgs,
  lib,
  ...
}:

let
  hasProxy = config.proxy.httpProxy != null;
  toYAML = lib.generators.toYAML { };

  # Inject api keys in runtime
  goose-cli' = pkgs.writeShellApplication {
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

      export GOOSE_DISABLE_KEYRING=1

      ${lib.optionalString hasProxy "export HTTPS_PROXY=${config.proxy.httpProxy}"}

      exec goose "$@"
    '';
  };
in
lib.mkIf config.purpose.dev.enable {
  age.secrets."api-keys".file = ../secrets/api-keys.age;

  home.packages = [ goose-cli' ];

  # goose config file
  xdg.configFile."goose/config.yaml".text = toYAML {
    # Model Configuration
    GOOSE_PROVIDER = "openai"; # siliconflow
    GOOSE_MODEL = "zai-org/glm-4.6";
    GOOSE_TEMPERATURE = 0.7;
    # siliconflow config
    OPENAI_BASE_PATH = "chat/completions";
    OPENAI_HOST = "https://api.siliconflow.cn/v1";

    # Planning Configuration
    GOOSE_PLANNER_PROVIDER = "openrouter";
    GOOSE_PLANNER_MODEL = "google/gemini-2.5-pro";

    # Tool Configuration
    GOOSE_MODE = "completely_autonomous"; # completely_autonomous, manual_approval, smart_approve, chat_only
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
