# Gopass password manager configuration
{
  config,
  pkgs,
  lib,
  ...
}:

let
  enable = config.purpose.daily;
in
{
  home.packages = lib.optionals enable [ pkgs.gopass ];

  xdg.configFile = lib.mkIf enable {
    "gopass/config".text = lib.generators.toGitINI {
      mounts.path = "${config.home.homeDirectory}/.local/share/gopass/stores/root";

      recipients = {
        check = true;
        hash = "6f65b0e43737ee1d6cb30fa6616f2b193b103fc0d8f86016975140d7fddbed8d";
      };

      age = {
        agent-enabled = true;
        agent-timeout = 3600;
      };

      show = {
        autoclip = true;
        safecontent = true;
      };
    };
  };

  programs.firefox.nativeMessagingHosts = lib.optionals enable [ pkgs.gopass-jsonapi ];
}
