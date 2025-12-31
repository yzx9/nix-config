{
  config,
  pkgs,
  lib,
  ...
}:

lib.mkMerge [
  {
    # The home.packages option allows you to install Nix packages into your
    # environment.
    home.packages = with pkgs; [
      # You can also create simple shell scripts directly inside your
      # configuration. For example, this adds a command 'my-hello' to your
      # environment:
      # (pkgs.writeShellScriptBin "my-hello" ''
      #   echo "Hello, ${config.home.username}!"
      # '')

      # shell tools
      # NOTE: override some of the darwin built-in tools
      coreutils
      curl
      gnutar
      gnugrep
      gnused
      # more common shell tools
      rsync
      unzip
      wget
      tree

      ripgrep # a line-oriented search tool
      neofetch # print information about your system
    ];
  }

  # Daily
  (lib.mkIf config.purpose.daily {
    home.packages = with pkgs; [
      # fantastic
      asciiquarium
      cmatrix
      sl

      # msic
      lazygit # simple terminal UI for git
      age # encryption tool
      glow # markdown viewer
      ouch # compressing and decompressing
    ];

    programs.zoxide.enable = true;
  })

  # Dev
  (lib.mkIf config.purpose.dev.enable {
    home.packages = with pkgs; [
      python3
      binutils
      just # command runner
      hyperfine # benchmarking tool
    ];

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    home.shellAliases.j = "just";
  })

  # Dev - Nix
  (lib.mkIf config.purpose.dev.nix.enable {
    home.packages = with pkgs; [
      hydra-check # check hydra status

      (nixpkgs-review.override {
        withNom = true;
        withDelta = true;
        withGlow = true;
      })
    ];
  })

  # Dev - Ops
  (lib.mkIf config.purpose.dev.ops.enable {
    home.packages = with pkgs; [
      lsof

      # networking tools
      # iputils
      mtr # a network diagnostic tool
      iperf3 # the ultimate speed test tool
      dnsutils # `dig` + `nslookup`
      ldns # replacement of `dig`, it provide the command `drill`
      socat # replacement of openbsd-netcat
      nmap # a utility for network discovery and security auditing
      ipcalc # it is a calculator for the IPv4/v6 addresses
    ];
  })
]
