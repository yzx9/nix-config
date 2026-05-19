inputs:

{
  default.imports = [
    ./frpc.nix
    ./paseo-relay.nix
  ];

  frpc.imports = [ ./frpc.nix ];
  paseo-relay.imports = [ ./paseo-relay.nix ];
}
