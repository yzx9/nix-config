{ config, lib, ... }:

let
  ssh = "${config.home.homeDirectory}/.ssh/";
  toSshPath = path: lib.removePrefix ssh path;

  needProxyCommand = !(builtins.isNull config.proxy.socksProxy);
  proxyCommand = lib.mkIf needProxyCommand "nc -v -x ${config.proxy.socksProxy} %h %p";
in
lib.mkMerge [
  {
    age.secrets."id-lab.pub" = {
      file = ../secrets/id-lab.pub.age;
      path = "${ssh}id_lab.pub";
      mode = "400";
    };

    programs.ssh = {
      enable = true;
      addKeysToAgent = "yes";

      matchBlocks = {
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

  (lib.mkIf config.vars.user.trusted {
    age.secrets = {
      id-lab = {
        file = ../secrets/id-lab.age;
        path = "${ssh}id_lab";
        mode = "400";
      };

      ssh-config = {
        file = ../secrets/ssh-config.age;
        path = "${ssh}config-agenix";
      };
    };

    programs.ssh.includes = [
      (toSshPath config.age.secrets.ssh-config.path)
    ];
  })
]
