{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    inputs.self.homeManagerModules.hapi-runner
  ];

  age.secrets = lib.mkIf config.purpose.dev.enable {
    "hapi-cli".file = ../../secrets/hapi-cli.age;
  };

  programs.hapi-runner = {
    enable = config.purpose.dev.enable;

    package = pkgs.writeShellApplication {
      name = "hapi";

      runtimeInputs = with pkgs; [
        yzx9.with-secrets
        yzx9.hapi
      ];

      text = ''
        with-secrets "${config.age.secrets."hapi-cli".path}" \
          --allow HAPI_API_URL \
          --allow CLI_API_TOKEN \
          -- hapi "$@"
      '';
    };
  };
}
