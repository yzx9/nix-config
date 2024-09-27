# nix-config

Personal nix-config.

Current state: nixos, darwin and standalone home-manager.

## Development

Test custom app: `nix-build -E 'with import <nixpkgs> {}; callPackage paht/to/package.nix {}'`

## Adding a host

1. Add the host to `hosts/`, include `config.nix`, `home.nix` and `host.nix`
2. Initialize the host keys, add public key to secrets, and re-encrypt secrets
3. Add the configurate to `flake.nix`
