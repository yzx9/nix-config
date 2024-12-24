# nix-config

Personal nix-config.

Current state: nixos, darwin and standalone home-manager.

## Development

Test custom app: `nix-build -E 'with import <nixpkgs> {}; callPackage paht/to/package.nix {}'`

## Adding a host

1. Add the host configuration to `hosts/{HOST_NAME}/default.nix`. Modify `home.nix` and `host.nix` as needed.
2. Generate the host keys, add the public key to your secrets, and re-encrypt the secrets.
3. Add the new host configuration to `hosts/default.nix`.
4. Deploy the configuration to your host.
   - If you're adding a new host with a standalone Home Manager setup, using `nix develop` might be helpful.
