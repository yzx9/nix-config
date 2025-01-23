{
  config,
  pkgs,
  lib,
  ...
}:

let
  toYAML = lib.generators.toYAML { };
  configFile = ".aider.conf.yml";
in
lib.mkIf config.purpose.daily {
  home.packages = [
    # API Keys and settings
    # NOTE: inject api_key in runtime due to the limitation of agnix
    (pkgs.writeShellScriptBin "aider" ''
      secretFile="${config.age.secrets.deepseek-api-key.path}"
      if [ -f "$secretFile" ]; then
          export DEEPSEEK_API_KEY="$(cat $secretFile)"
      else
          echo "Warning: Secret file $secretFile does not exist, no api_key injected."
      fi

      ${lib.getExe pkgs.aider-chat}
    '')
  ];

  age.secrets."deepseek-api-key".file = ../../secrets/deepseek-api-key.age;

  home.file.${configFile}.text = toYAML {
    #############
    # Main model:

    # Specify the model to use for the main chat
    model = "deepseek/deepseek-chat";

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
