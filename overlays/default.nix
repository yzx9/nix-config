{ nixpkgs, ... }@inputs:

let
  inherit (nixpkgs) lib;

  overlays = {
    aim = import ./aim.nix inputs;
    nur = import ./nur.nix inputs;
    packages = import ./packages.nix inputs;

    gopass = import ./gopass.nix;
    python-pandas-stubs = import ./python-pandas-stubs.nix;
    terminal-notifier = import ./terminal-notifier.nix;
  };
in
overlays
// {
  default = lib.composeManyExtensions (lib.attrValues overlays);
}
