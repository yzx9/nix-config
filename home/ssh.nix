{ config, lib, ... }:

let
  ssh = "${config.home.homeDirectory}/.ssh/";
  toSshPath = path: lib.removePrefix ssh path;

  needProxyCommand = !(builtins.isNull config.proxy.socksProxy);
  proxyCommand = lib.mkIf needProxyCommand "nc -v -x ${config.proxy.socksProxy} %h %p";
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
        forwardAgent = true;
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
        extraOptions.TCPKeepAlive = "yes";
      };
    };
  };
}
