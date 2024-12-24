# nix-config

Personal nix-config.

Current state: nixos, darwin and standalone home-manager.

## Development

Test custom app: `nix-build -E 'with import <nixpkgs> {}; callPackage paht/to/package.nix {}'`

## Adding a host

1. Add the host to `hosts/{HOST_NAME}/default.nix`, configurate `home.nix` and `host.nix` if needed
2. Initialize the host keys, add public key to secrets, and re-encrypt secrets
3. Add the configurate to `hosts/default.nix`
4. Deploy the configuration to your host
   - If you are add new host with standalone home-manager, `nix develop` might be helpful
