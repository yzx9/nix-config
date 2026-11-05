inputs:

{
  default.imports = [
    ./frpc.nix
    ./signoz.nix
  ];

  frpc.imports = [ ./frpc.nix ];

  signoz.imports = [ ./signoz.nix ];
}
