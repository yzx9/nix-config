{ ... }:

{
  imports = [
    ../shared
    ./docker.nix
    ./homebrew.nix
    ./nix-core.nix
    ./system.nix
  ];
}
