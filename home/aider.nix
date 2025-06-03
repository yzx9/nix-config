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
  model = "gemini/gemini-2.5-flash-preview-05-20";
  # weakModel = "gemini/gemini-2.5-flash-preview-05-20";

  # Inject api keys in runtime due to the limitation of agnix
  pkg = pkgs.writeShellScriptBin "aider" ''
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

    ${lib.getExe pkgs.aider-chat} $@
  '';
in
lib.mkIf config.purpose.dev.enable {

  age.secrets."api-keys".file = ../secrets/api-keys.age;

  home.packages = [ pkg ];

  home.file.".aider.conf.yml".text = lib.generators.toYAML { } {
    #############
    # Main model:

    # Specify the model to use for the main chat
    model = model;

    # Specify the model to use for commit messages and chat history summarization (default depends on --model)
    # weak-model = weakModel;

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
