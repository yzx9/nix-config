{ pkgs, ... }:

let
  dbeaver-bin = pkgs.callPackage ./custom-apps/dbeaver-bin.nix { };
in
{
  # # Allow unfree packages
  # nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ ];

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # You can also create simple shell scripts directly inside your
    # configuration. For example, this adds a command 'my-hello' to your
    # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')

    # dev
    devenv
    nil
    nixfmt-rfc-style
    cargo
    rustc
    go
    python312
    nodejs
    corepack
    dbeaver-bin # SQL client

    # networking tools
    mtr # a network diagnostic tool
    iperf3 # the ultimate speed test tool
    dnsutils # `dig` + `nslookup`
    ldns # replacement of `dig`, it provide the command `drill`
    socat # replacement of openbsd-netcat
    nmap # a utility for network discovery and security auditing
    ipcalc # it is a calculator for the IPv4/v6 addresses

    # misc
    age
    neofetch
    just
    gopass
    gopass-jsonapi # you have to run `gopass-jsonapi configure` mannually, because I dont know how to do it automatically
    # inkscape    # SVG design
  ];

  programs.gpg = {
    enable = true;
    settings = {
      keyid-format = "0xlong";
      with-fingerprint = true;
    };
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
  };
}
