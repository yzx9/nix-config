{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:

{
  imports = [ inputs.self.homeManagerModules.paseo ];

  age.secrets = lib.mkIf config.purpose.dev.enable {
    "paseo".file = ../../secrets/paseo.age;
  };

  programs.paseo = {
    enable = config.purpose.dev.enable;

    package = pkgs.writeShellApplication {
      name = "paseo";

      runtimeInputs = with pkgs.yzx9; [
        with-secrets
        paseo
      ];

      text = ''
        with-secrets "${config.age.secrets."paseo".path}" \
          --allow PASEO_PUBLIC_ENDPOINT \
          -- paseo "$@"
      '';
    };

    relay = {
      enable = true;
      endpoint = "10.6.141.234:51185";
    };
  };
}
