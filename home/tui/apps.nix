{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Allow unfree packages
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ ];

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages =
    (with pkgs; [
      # You can also create simple shell scripts directly inside your
      # configuration. For example, this adds a command 'my-hello' to your
      # environment:
      # (pkgs.writeShellScriptBin "my-hello" ''
      #   echo "Hello, ${config.home.username}!"
      # '')

      ncurses
      tree
      neofetch

      # TODO: change to config
      (if config.nvidia.enable then (btop.override { cudaSupport = true; }) else btop)

      # shell tools
      # NOTE: may override some of the darwin built-in tools
      coreutils
      gnutar
      wget
      curl
      unzip
    ])
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux (
      with pkgs;
      [
        parted
      ]
    );
}
