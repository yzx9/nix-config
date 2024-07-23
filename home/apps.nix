{ pkgs, lib, ... }:

{
  # Allow unfree packages
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "Xcode.app" ];

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages =
    (with pkgs;
    [
      # You can also create simple shell scripts directly inside your
      # configuration. For example, this adds a command 'my-hello' to your
      # environment:
      # (pkgs.writeShellScriptBin "my-hello" ''
      #   echo "Hello, ${config.home.username}!"
      # '')

      # shell tools
      bat
      wget
      curl
      unzip
      nnn
      tree

      # networking tools
      # iputils
      mtr # a network diagnostic tool
      iperf3 # the ultimate speed test tool
      dnsutils # `dig` + `nslookup`
      ldns # replacement of `dig`, it provide the command `drill`
      socat # replacement of openbsd-netcat
      nmap # a utility for network discovery and security auditing
      ipcalc # it is a calculator for the IPv4/v6 addresses

      # dev
      nodejs
      corepack
      go
      python312
      cargo
      rustc
      nixpkgs-review

      # misc
      age
      neofetch
      just
      gopass
    ]);

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
  };
}
