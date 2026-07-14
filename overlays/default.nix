{ nixpkgs, ... }@inputs:

let
  inherit (nixpkgs) lib;

  overlays = {
    aim = import ./aim.nix inputs;
    gopass = import ./gopass.nix inputs;
    nur = import ./nur.nix inputs;
    packages = import ./packages.nix inputs;
    python-packages = import ./python-packages.nix inputs;
    stats = import ./stats.nix inputs;
    terminal-notifier = import ./terminal-notifier.nix inputs;
    zotero = import ./zotero.nix inputs;
  };
in
overlays
// {
  default = lib.composeManyExtensions (lib.attrValues overlays);
}
