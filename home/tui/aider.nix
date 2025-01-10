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
{
  home.packages = [ pkgs.aider-chat ];

  home.file.${configFile}.text = toYAML {
    #############
    # Main model:

    # Specify the model to use for the main chat
    model = "deepseek/deepseek-chat";

    ########################
    # API Keys and settings:

    api-key = "deepseek=${placeholder}";
  };

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
}
