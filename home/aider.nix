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
  #  - gemini/gemini-2.0-flash
  model = "gemini/gemini-2.5-pro-exp-03-25";
  weakModel = "gemini/gemini-2.0-flash";

  toYAML = lib.generators.toYAML { };

  version = "0.81.1";
  pkg = pkgs.aider-chat.overridePythonAttrs (old: {
    inherit version;
    src = pkgs.fetchFromGitHub {
      owner = "Aider-AI";
      repo = "aider";
      tag = "v${version}";
      hash = "sha256-TNSdsJBmF/9OCkFe1dZV0y7X2FSTjgp3YV4HGlA9GMc=";
    };
  });
in
lib.mkIf config.purpose.daily {
  home.packages = [
    # API Keys and settings
    # NOTE: inject api_key in runtime due to the limitation of agnix
    (pkgs.writeShellScriptBin "aider" ''
      declare -A secrets=(
        ["DEEPSEEK_API_KEY"]="${config.age.secrets.api-key-deepseek.path}"
        ["GEMINI_API_KEY"]="${config.age.secrets.api-key-gemini.path}"
        ["OPENAI_API_KEY"]="${config.age.secrets.api-key-siliconflow.path}" # siliconflow, openai compatible
        ["OPENROUTER_API_KEY"]="${config.age.secrets.api-key-openrouter.path}"
      )

      for envVar in "''${!secrets[@]}"; do
        secretFile="''${secrets[$envVar]}"

        if [ -f "$secretFile" ]; then
          export "$envVar"="$(cat "$secretFile")"
        else
          echo "Warning: Secret file $secretFile does not exist, no api_key injected for $envVar."
        fi
      done

      export OPENAI_API_BASE="https://api.siliconflow.cn/v1"

      ${lib.optionalString hasProxy "export HTTPS_PROXY=${config.proxy.httpProxy}"}

      ${lib.getExe pkg} $@
    '')
  ];

  age.secrets."api-key-deepseek".file = ../secrets/api-key-deepseek.age;
  age.secrets."api-key-gemini".file = ../secrets/api-key-gemini.age;
  age.secrets."api-key-openrouter".file = ../secrets/api-key-openrouter.age;
  age.secrets."api-key-siliconflow".file = ../secrets/api-key-siliconflow.age;

  home.file.".aider.conf.yml".text = toYAML {
    #############
    # Main model:

    # Specify the model to use for the main chat
    model = model;

    # Specify the model to use for commit messages and chat history summarization (default depends on --model)
    weak-model = weakModel;

    ###############
    # Git settings:

    # Attribute aider code changes in the git author name (default: True)
    attribute-author = false;

    # Attribute aider commits in the git committer name (default: True)
    attribute-committer = false;

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
}
