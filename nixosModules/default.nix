inputs:

{
  default.imports = [
    ./frpc.nix
    ./hapi-hub.nix
    ./paseo-relay.nix
  ];

  frpc.imports = [ ./frpc.nix ];
  hapi-hub.imports = [ ./hapi-hub.nix ];
  paseo-relay.imports = [ ./paseo-relay.nix ];
}
