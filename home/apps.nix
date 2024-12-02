{
  config,
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
      wget
      curl
      unzip

      # misc
      age
      just
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      parted
    ]
    ++ lib.optionals config.purpose.daily [
      # networking tools
      # iputils
      mtr # a network diagnostic tool
      iperf3 # the ultimate speed test tool
      dnsutils # `dig` + `nslookup`
      ldns # replacement of `dig`, it provide the command `drill`
      socat # replacement of openbsd-netcat
      nmap # a utility for network discovery and security auditing
      ipcalc # it is a calculator for the IPv4/v6 addresses

      # msic
      gopass
      ffmpeg
    ]
    ++ lib.optionals config.purpose.development [
      python312
      nixpkgs-review
    ]
  );

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };

  home.shellAliases.j = "just";
}
