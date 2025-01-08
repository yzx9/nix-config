# nix-config

Personal nix-config.

Current state: nixos, darwin and standalone home-manager.

## Development

Build custom package:

```path
nix build .#PACKAGE
```

## Adding a host

1. Add the host configuration to `hosts/{HOST_NAME}/default.nix`. Modify `home.nix` and `host.nix` as needed.
2. Generate the host keys, add the public key to your secrets, and re-encrypt the secrets.
3. Add the new host configuration to `hosts/default.nix`.
4. Deploy the configuration to your host.
   - If you're adding a new host with a standalone Home Manager setup, using `nix develop` might be helpful.

## Known issues

### Home Manager + Agenix

Each time when you add/edit/delete home secrets, you will have to run the following script manually:

```
systemctl --user start agenix.service
```

This is [a bug with agenix](https://github.com/ryantm/agenix/issues/50#issuecomment-1712597733)
