{
  config,
  pkgs,
  lib,
  ...
}:

lib.mkMerge [
  {
    # Allow unfree packages
    # nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ ];

    # The home.packages option allows you to install Nix packages into your
    # environment.
    home.packages =
      [
        # You can also create simple shell scripts directly inside your
        # configuration. For example, this adds a command 'my-hello' to your
        # environment:
        # (pkgs.writeShellScriptBin "my-hello" ''
        #   echo "Hello, ${config.home.username}!"
        # '')

        pkgs.ncurses
        pkgs.tree
        pkgs.neofetch

        # TODO: change to config
        (if config.nvidia.enable then (pkgs.btop.override { cudaSupport = true; }) else pkgs.btop)

        # shell tools
        # NOTE: may override some of the darwin built-in tools
        pkgs.coreutils
        pkgs.gnutar
        pkgs.wget
        pkgs.curl
        pkgs.unzip
      ]
      ++ lib.optionals pkgs.stdenvNoCC.hostPlatform.isLinux [
        pkgs.parted
      ];
  }

  (lib.mkIf config.purpose.daily {
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
      ouch # compressing and decompressing
    ];

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };

    home.shellAliases.j = "just";
  })
]
