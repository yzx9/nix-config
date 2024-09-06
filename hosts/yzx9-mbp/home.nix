{ config, lib, ... }:

{
  age.secrets.ssh-config = {
    file = ../../secrets/ssh-config-yzx9-mbp.age;
    path = "${config.home.homeDirectory}/.ssh/config-agenix";
  };

  programs.ssh.includes = [
    (lib.removePrefix "${config.home.homeDirectory}/.ssh/" "config-agenix")
  ];
}
