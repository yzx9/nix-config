{ pkgs, ... }:

{
  home.packages = [ pkgs.proxychains-ng ];

  home.file.".proxychains/proxychains.conf".text = ''
    [ProxyList]
    socks5 127.0.0.1 10086
  '';
}
