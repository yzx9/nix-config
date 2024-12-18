{ nixpkgs, ... }@inputs:

let
  inherit (nixpkgs) lib;
  recursiveMergeAttrs =
    listOfAttrsets: lib.fold (attrset: acc: lib.recursiveUpdate attrset acc) { } listOfAttrsets;
in
recursiveMergeAttrs [
  (import ./cvcd-gpu0/default.nix inputs)
  (import ./cvcd-gpu1/default.nix inputs)
  (import ./yzx9-mbp/default.nix inputs)
  (import ./yzx9-rpi5/default.nix inputs)
  (import ./yzx9-ws/default.nix inputs)
]
