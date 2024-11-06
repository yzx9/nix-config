{ ... }:

{
  imports = [
    ../shared
    ./docker.nix
    ./nvidia.nix
    ./proxy.nix
    ./system.nix
  ];
}
