{ lib, ... }:

let
  inherit (import ../_shared.nix) mkNetworkingLab;
in
{
  networking = lib.mkMerge [
    (mkNetworkingLab "enp2s0" "10.6.141.235")

    {
      firewall = {
        extraCommands = ''
          ip46tables -N nixos-extra 2>/dev/null || true
          ip46tables -C INPUT -j nixos-extra 2>/dev/null || ip46tables -A INPUT -j nixos-extra
          ip46tables -F nixos-extra

          # IPv4: allow HTTP, HTTPS, common development ports from 10.6.141.0/24
          iptables -A nixos-extra -s 10.6.141.0/24 -p tcp -m multiport --dports 30202 -j ACCEPT
        '';

        extraStopCommands = ''
          ip46tables -D INPUT -j nixos-extra 2>/dev/null || true
          ip46tables -F nixos-extra 2>/dev/null || true
          ip46tables -X nixos-extra 2>/dev/null || true
        '';
      };
    }
  ];
}
