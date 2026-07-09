{ nixpkgs, ... }@inputs:

let
  inherit (nixpkgs) lib;

  overlays = {
    ctranslate2 = import ./ctranslate2.nix inputs;
    aim = import ./aim.nix inputs;
    nur = import ./nur.nix inputs;
    packages = import ./packages.nix inputs;
    python-packages = import ./python-packages.nix inputs;
    worktrunk = import ./worktrunk.nix inputs;
    zotero = import ./zotero.nix inputs;
  };
in
overlays
// {
  default = lib.composeManyExtensions (lib.attrValues overlays);
}
