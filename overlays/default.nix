{ nixpkgs, ... }@inputs:

let
  inherit (nixpkgs) lib;

  overlays = {
    aim = import ./aim.nix inputs;
    nur = import ./nur.nix inputs;
    packages = import ./packages.nix inputs;

    claude-code = import ./claude-code.nix;
    gopass = import ./gopass.nix;
    terminal-notifier = import ./terminal-notifier.nix;
    yazi = import ./yazi;
  };
in
overlays
// {
  default = lib.composeManyExtensions (lib.attrValues overlays);
}
