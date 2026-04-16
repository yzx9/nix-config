inputs:

{
  default.imports = [
    ./frpc.nix
    ./hapi-hub.nix
  ];

  frpc.imports = [ ./frpc.nix ];
  hapi-hub.imports = [ ./hapi-hub.nix ];
}
