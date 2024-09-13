{ config, lib, ... }:

let
  ssh = "${config.home.homeDirectory}/.ssh/";
  toSshPath = path: lib.removePrefix ssh path;
in
{
  age.secrets = {
    ssh-config = {
      file = ../secrets/ssh-config.age;
      path = "${ssh}config-agenix";
    };
  };

  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";

    includes = [
      (toSshPath config.age.secrets.ssh-config.path)
    ];

    matchBlocks = {
      "github.com" = {
        # ProxyCommand nc -v -x 127.0.0.1:10086 %h %p
        # UseKeychain yes
        hostname = "github.com";
        user = "git";
        extraOptions = {
          TCPKeepAlive = "yes";
        };
      };

      "ssh.github.com" = {
        hostname = "ssh.github.com";
        port = 443;
        user = "git";
        extraOptions = {
          TCPKeepAlive = "yes";
        };
      };
    };
  };
}
