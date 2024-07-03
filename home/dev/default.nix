{ ... }:

{
  imports = [
    ./docker.nix
    ./frontend.nix
    ./go.nix
    ./markdown.nix
    ./nix.nix
    ./python.nix
    ./rust.nix
  ];
}
