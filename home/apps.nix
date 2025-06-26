{
  config,
  inputs,
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
      # more shell tools
      unzip
      wget
      tree

      neofetch # print information about your system
      ouch # compressing and decompressing
    ];
  }

  # Daily
  (lib.mkIf config.purpose.daily {
    home.packages =
      with pkgs;
      [
        # fantastic
        asciiquarium
        cmatrix
        sl

        # msic
        age # encryption tool
        gopass # password manager
      ]
      ++ lib.optionals config.purpose.gui [
        # you have to run `gopass-jsonapi configure` manually, because I dont know how to
        # do it automatically
        gopass-jsonapi # TODO: move to firefox.nix
      ];
  })

  # Dev
  (lib.mkIf config.purpose.dev.enable {
    home.packages = with pkgs; [
      python313
      just # command runner
      hyperfine # benchmarking tool
      gitmoji-cli
    ];

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };

    home.shellAliases.j = "just";

    # gitmoji-cli
    home.file.".gitmojirc.json".text = lib.strings.toJSON {
      "autoAdd" = false;
      "emojiFormat" = "emoji";
      "scopePrompt" = true;
      "messagePrompt" = true;
      "capitalizeTitle" = true;
      "gitmojisUrl" = "https://gitmoji.dev/api/gitmojis";
    };
  })

  # DevOps
  (lib.mkIf config.purpose.dev.devops.enable {
    home.packages = with pkgs; [
      # networking tools
      # iputils
      mtr # a network diagnostic tool
      iperf3 # the ultimate speed test tool
      dnsutils # `dig` + `nslookup`
      ldns # replacement of `dig`, it provide the command `drill`
      socat # replacement of openbsd-netcat
      nmap # a utility for network discovery and security auditing
      ipcalc # it is a calculator for the IPv4/v6 addresses

      lsof
    ];
  })

  # Dev - Nix
  (lib.mkIf config.purpose.dev.nix.enable {
    home.packages = with pkgs; [
      hydra-check # check hydra status
      nixpkgs-review
      nix-output-monitor
    ];
  })
]
