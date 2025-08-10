{
  config,
  pkgs,
  lib,
  ...
}:

let
  hasProxy = !(builtins.isNull config.proxy.httpProxy);

  # Configured:
  #  - deepseek/deepseek-chat
  #  - gemini/gemini-2.5-pro
  #  - gemini/gemini-2.5-flash
  #  - openai/Qwen/Qwen3-{8,14,32}B # siliconflow
  #  - openai/moonshotai/Kimi-Dev-72B # siliconflow
  model = "openai/Qwen/Qwen3-Coder-480B-A35B-Instruct";
  weakModel = "openai/Qwen/Qwen3-32B";
in
lib.mkIf config.purpose.dev.enable {
  age.secrets."api-keys".file = ../secrets/api-keys.age;

  home.packages = [
    # Inject api keys in runtime due to the limitation of agnix
    (pkgs.writeShellApplication {
      name = "aider";
      runtimeInputs = [
        pkgs.aider-chat-with-playwright
      ];
      text = ''
        declare -A secrets

        while IFS='=' read -r key value; do
          [[ -z "$key" ]] && continue # ignore empty lines
          [[ "$key" == \#* ]] && continue # ignore comments
          secrets["@$key@"]="$value"
        done < "${config.age.secrets."api-keys".path}"

        declare -A mapping=(
          ["DEEPSEEK_API_KEY"]="@deepseek@"
          ["GEMINI_API_KEY"]="@gemini@"
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

        export OPENAI_API_BASE="https://api.siliconflow.cn/v1"

        ${lib.optionalString hasProxy "export HTTPS_PROXY=${config.proxy.httpProxy}"}

        exec aider "$@"
      '';
    })
  ];

  home.file.".aider.conf.yml".text = lib.generators.toYAML { } {
    #############
    # Main model:

    # Specify the model to use for the main chat
    model = model;

    # Specify the model to use for commit messages and chat history summarization (default depends on --model)
    weak-model = weakModel;

    ###############
    # Git settings:

    # Attribute aider code changes in the git author name (default: True). If explicitly set to True, overrides --attribute-co-authored-by precedence.
    attribute-author = false;

    # Attribute aider commits in the git committer name (default: True). If explicitly set to True, overrides --attribute-co-authored-by precedence for aider edits.
    attribute-committer = false;

    # Prefix commit messages with 'aider: ' if aider authored the changes (default: False)
    attribute-commit-message-author = false;

    ## Prefix all commit messages with 'aider: ' (default: False)
    attribute-commit-message-committer = false;

    # Attribute aider edits using the Co-authored-by trailer in the commit message (default: True). If True, this takes precedence over default --attribute-author and --attribute-committer behavior unless they are explicitly set to True.
    attribute-co-authored-by = false;

    ########################
    # Fixing and committing:

    ## Specify lint commands to run for different languages, eg: "python: flake8 --select=..." (can be used multiple times)
    #lint-cmd: xxx
    # Specify multiple values like this:
    lint-cmd = [
      "python: ${lib.getExe pkgs.ruff} check --fix"
    ];

    #################
    # Other settings:

    ## Use VI editing mode in the terminal (default: False)
    vim = true;
  };

  home.file.".aider.model.metadata.json".text = builtins.toJSON (
    lib.genAttrs
      [
        "openai/Qwen/Qwen3-8B"
        "openai/Qwen/Qwen3-14B"
        "openai/Qwen/Qwen3-32B"
        "openai/Qwen/Qwen3-Coder-480B-A35B-Instruct"
        "openai/moonshotai/Kimi-Dev-72B"
        "openai/moonshotai/Kimi-K2-Instruct"
        "openai/Pro/moonshotai/Kimi-K2-Instruct"
      ]
      (_: {
        "max_tokens" = 8192;
        "max_input_tokens" = 128000;
        "max_output_tokens" = 8192;
        # "input_cost_per_token" = 4 e-07;
        # "output_cost_per_token" = 8 e-07;
        # "litellm_provider"= "siliconflow";
        "supports_function_calling" = true;
        "supports_tool_choice" = true;
        "supports_reasoning" = true;
        "mode" = "chat";
        "source" = "https://cloud.siliconflow.cn/models";
      })
  );
}
