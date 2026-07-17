{ nixpkgs, ... }@inputs:

let
  inherit (nixpkgs) lib;

  overlays = {
    aim = import ./aim.nix inputs;
    claude-code = import ./claude-code.nix inputs;
    gopass = import ./gopass.nix inputs;
    nur = import ./nur.nix inputs;
    packages = import ./packages.nix inputs;
    python-fastmcp = import ./python-fastmcp.nix inputs;
    python-pandas-stubs = import ./python-pandas-stubs.nix inputs;
    stats = import ./stats.nix inputs;
    terminal-notifier = import ./terminal-notifier.nix inputs;
    zotero = import ./zotero.nix inputs;
  };
in
overlays
// {
  default = lib.composeManyExtensions (lib.attrValues overlays);
}
