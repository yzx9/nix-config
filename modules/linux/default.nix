{ ... }:

{
  imports = [
    ../shared
    ./docker.nix
    ./nvidia.nix
    ./system.nix
  ];
}
