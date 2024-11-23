{ ... }:

{
  imports = [
    ../_shared
    ./docker.nix
    ./homebrew.nix
    ./nix-core.nix
    ./proxy.nix
    ./system.nix
  ];
}
