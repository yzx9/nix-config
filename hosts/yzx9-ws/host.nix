{ ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    ./frp.nix
    ./proxy.nix
    ./rss.nix
    ./xorg.nix
  ];
}
