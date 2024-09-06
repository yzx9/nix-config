{ config, lib, ... }:

{
  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";

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
