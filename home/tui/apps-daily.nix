{
  config,
  pkgs,
  lib,
  ...
}:

lib.mkIf config.purpose.daily {
  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    hydra-check # check hydra status
    nixpkgs-review

    # networking tools
    # iputils
    mtr # a network diagnostic tool
    iperf3 # the ultimate speed test tool
    dnsutils # `dig` + `nslookup`
    ldns # replacement of `dig`, it provide the command `drill`
    socat # replacement of openbsd-netcat
    nmap # a utility for network discovery and security auditing
    ipcalc # it is a calculator for the IPv4/v6 addresses

    # fantastic
    asciiquarium
    cmatrix
    sl

    # dev
    python313
    just # command runner

    # msic
    age
    ffmpeg
  ];

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  home.shellAliases.y = "yazi";
  home.shellAliases.j = "just";
}
