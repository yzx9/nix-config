{ config, lib, ... }:

let
  ssh = "${config.home.homeDirectory}/.ssh/";
  toSshPath = path: lib.removePrefix ssh path;

  hasProxy = config.proxy.socks5Port != null;
  proxyCommand = lib.mkIf hasProxy "nc -v -x 127.0.0.1:${toString config.proxy.socks5Port} %h %p";
in
{
  age.secrets.ssh-config = {
    file = ../secrets/ssh-config.age;
    path = "${ssh}config-agenix";
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    includes = [
      (toSshPath config.age.secrets.ssh-config.path)
    ];

    matchBlocks = {
      "*" = {
        addKeysToAgent = "yes";
        forwardAgent = false;
        forwardX11 = false;
        serverAliveInterval = 0;
        serverAliveCountMax = 3;
      };

      "github.com" = {
        hostname = "github.com";
        user = "git";
        proxyCommand = proxyCommand;
        extraOptions.TCPKeepAlive = "yes";
      };

      "ssh.github.com" = {
        hostname = "ssh.github.com";
        port = 443;
        user = "git";
        proxyCommand = proxyCommand;
        extraOptions.TCPKeepAlive = "yes";
      };
    };
  };
}
