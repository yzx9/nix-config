{ pkgs, lib, username, ... }:

let
  dbeaver = pkgs.callPackage ./dbeaver.nix { };
in
{
  fonts.fontconfig.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "code"
    "vscode"
  ];

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # It is sometimes useful to fine-tune packages, for example, by applying
    # overrides. You can do that directly here, just don't forget the
    # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # fonts?
    (nerdfonts.override { fonts = [ "CascadiaCode" "FiraCode" ]; }) # Nerd Font patched

    # You can also create simple shell scripts directly inside your
    # configuration. For example, this adds a command 'my-hello' to your
    # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')

    # dev
    devenv
    nil
    nixpkgs-fmt
    cargo
    rustc
    go
    python312
    nodejs
    corepack
    dbeaver # SQL client

    # networking tools
    mtr # a network diagnostic tool
    iperf3 # the ultimate speed test tool
    dnsutils # `dig` + `nslookup`
    ldns # replacement of `dig`, it provide the command `drill`
    socat # replacement of openbsd-netcat
    nmap # a utility for network discovery and security auditing
    ipcalc # it is a calculator for the IPv4/v6 addresses

    # misc
    neofetch
    just
    # inkscape    # SVG design
  ];

  programs.gpg = {
    enable = true;
    settings = {
      keyid-format = "0xlong";
      with-fingerprint = true;
    };
  };

  programs.git = {
    enable = true;
    signing = {
      key = "0xC2DD1916FE471BE2";
      signByDefault = true;
    };
  };

  # programs.vscode = {
  #   enable = true;
  #   # needed for rust lang server and rust-analyzer extension
  #   package = pkgs.vscode.fhsWithPackages (ps: with ps; [ rustup zlib openssl.dev pkg-config ]);
  # };
}
