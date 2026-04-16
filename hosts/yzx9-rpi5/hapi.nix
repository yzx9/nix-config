{
  config,
  pkgs,
  lib,
  ...
}:

let
  package = pkgs.writeShellApplication {
    name = "hapi";

    runtimeInputs = with pkgs; [
      yzx9.with-secrets
      yzx9.hapi
    ];

    text = ''
      with-secrets "${config.age.secrets."hapi-cli".path}" \
        --allow HAPI_PUBLIC_URL \
        -- hapi "$@"
    '';
  };

  port = 27872;
in
{
  age.secrets."hapi-cli" = {
    file = ../../secrets/hapi-cli.age;
    owner = config.services.hapi-hub.user;
  };

  services.hapi-hub = {
    inherit package port;

    enable = true;
    host = "0.0.0.0";
  };

  networking.firewall.allowedTCPPorts = [ port ];
}
