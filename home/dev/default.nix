{ pkgs, ... }:

{
  imports = [
    ./frontend.nix
    ./go.nix
    ./nix.nix
  ];

  home.packages = with pkgs; [
    # dev tools
    python312

    # dev - rust
    cargo
    rustc
    rust-analyzer
  ];
}
