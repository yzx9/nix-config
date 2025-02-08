{
  config,
  pkgs,
  lib,
  ...
}:

let
  hasProxy = !(builtins.isNull config.proxy.httpProxy);
  useGemini = hasProxy;

  toYAML = lib.generators.toYAML { };
in
lib.mkIf config.purpose.daily {
  home.packages = [
    # API Keys and settings
    # NOTE: inject api_key in runtime due to the limitation of agnix
    (pkgs.writeShellScriptBin "aider" ''
      declare -A secrets=(
        ["DEEPSEEK_API_KEY"]="${config.age.secrets.api-key-deepseek.path}"
        ["GEMINI_API_KEY"]="${config.age.secrets.api-key-gemini.path}"
      )

      for envVar in "''${!secrets[@]}"; do
        secretFile="''${secrets[$envVar]}"

        if [ -f "$secretFile" ]; then
          export "$envVar"="$(cat "$secretFile")"
        else
          echo "Warning: Secret file $secretFile does not exist, no api_key injected for $envVar."
        fi
      done

      ${lib.optionalString hasProxy "export HTTPS_PROXY=${config.proxy.httpProxy}"}

      ${lib.getExe pkgs.aider-chat} $@
    '')
  ];

  age.secrets."api-key-deepseek".file = ../../secrets/api-key-deepseek.age;
  age.secrets."api-key-gemini".file = ../../secrets/api-key-gemini.age;

  home.file.".aider.conf.yml".text = toYAML {
    #############
    # Main model:

    # Specify the model to use for the main chat
    model = if useGemini then "gemini/gemini-2.0-flash" else "deepseek/deepseek-chat";

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
  };
}
