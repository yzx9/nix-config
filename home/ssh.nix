{ config, lib, ... }:

let
  ssh = "${config.home.homeDirectory}/.ssh/";
  toSshPath = path: lib.removePrefix ssh path;

  hasProxy = config.my.proxy.socks5Port != null;
  proxyCommand = lib.mkIf hasProxy "nc -v -x 127.0.0.1:${toString config.my.proxy.socks5Port} %h %p";
in
{
  age.secrets = lib.mkMerge [
    {
      ssh-config = {
        file = ../secrets/ssh-config.age;
        path = "${ssh}config-agenix";
      };
    }

    (lib.mkIf config.my.host.trusted {
      id-auth = {
        file = ../secrets/id-auth.age;
        path = "${ssh}id_auth";
        mode = "400";
      };
    })
  ];

  home.file.".ssh/id_auth.pub".source = ../secrets/id-auth.pub;

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    includes = [
      (toSshPath config.age.secrets.ssh-config.path)
    ];

    settings = {
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
        TCPKeepAlive = "yes";
      };

      "ssh.github.com" = {
        hostname = "ssh.github.com";
        port = 443;
        user = "git";
        proxyCommand = proxyCommand;
        TCPKeepAlive = "yes";
      };
    };
  };
}
