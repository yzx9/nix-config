{
  config,
  pkgs,
  lib,
  ...
}:

{
  allowedUnfree = [ "n8n" ];

  services.n8n = {
    enable = true;
    openFirewall = true;

    environment = {
      # NOTE: try to remove this
      N8N_SECURE_COOKIE = false;
    };
  };
}
