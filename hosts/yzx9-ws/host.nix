{ ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    ./nvidia.nix
  ];

  # Configure network proxy if necessary
  networking.proxy.default = "http://10.3.1.201:12345/";
  networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
}
