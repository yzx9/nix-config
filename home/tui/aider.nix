{ config, pkgs, ... }:

{
  home.packages = [ pkgs.aider-chat ];

  age.secrets."aider.conf.yml" = {
    file = ../../secrets/aider.conf.yml.age;
    path = "${config.home.homeDirectory}/.aider.conf.yml";
    mode = "400";
  };
}
