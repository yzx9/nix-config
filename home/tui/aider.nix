{
  config,
  pkgs,
  lib,
  ...
}:

let
  toYAML = lib.generators.toYAML { };
  configFile = ".aider.conf.yml";
  placeholder = "@DEEPSEEK_API_KEY@";
in
lib.mkIf config.purpose.daily {
  home.packages = [
    pkgs.aider-chat
    pkgs.ruff
  ];

  age.secrets."deepseek-api-key".file = ../../secrets/deepseek-api-key.age;

  home.activation = {
    removeAiderConfig = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      rm -f ${config.home.homeDirectory}/${configFile}
    '';

    fillAiderSecret = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      secretFile="${config.age.secrets.deepseek-api-key.path}"
      if [ -f "$secretFile" ]; then
          secret="$(cat "$secretFile")"
          configFile="${config.home.homeDirectory}/${configFile}"
          verboseEcho "Replacing placeholder with secret in config file: $configFile"
          run ${pkgs.gnused}/bin/sed -i "s#${placeholder}#$secret#" "$configFile"
      else
          verboseEcho "Warning: Secret file $secretFile does not exist. Skipping placeholder replacement."
      fi
    '';
  };

  home.file.${configFile}.text = toYAML {
    #############
    # Main model:

    # Specify the model to use for the main chat
    model = "deepseek/deepseek-chat";

    ########################
    # API Keys and settings:

    ## Set an API key for a provider (eg: --api-key provider=<key> sets PROVIDER_API_KEY=<key>)
    #api-key: xxx
    ## Specify multiple values like this:
    api-key = "deepseek=${placeholder}";

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
      "python: ruff check --fix"
    ];
  };
}
