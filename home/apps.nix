{
  inputs,
  vars,
  pkgs,
  lib,
  ...
}:

{
  # Allow unfree packages
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ ];

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = (
    with pkgs;
    [
      # You can also create simple shell scripts directly inside your
      # configuration. For example, this adds a command 'my-hello' to your
      # environment:
      # (pkgs.writeShellScriptBin "my-hello" ''
      #   echo "Hello, ${config.home.username}!"
      # '')

      # nix related
      inputs.agenix.packages.${vars.system}.default

      # shell tools
      ncurses
      bat
      wget
      curl
      unzip
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

      # misc
      age
      just
      gopass
      ffmpeg
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      parted
    ]
  );

  home.shellAliases.j = "just";
}
