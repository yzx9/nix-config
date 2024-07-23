# nix-config

Personal nix-config.

Current state: darwin only.

## Development

Test custom app: `nix-build -E 'with import <nixpkgs> {}; callPackage paht/to/package.nix {}'`

