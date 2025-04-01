# nix-config

Personal nix-config.

Current state: nixos, darwin and standalone home-manager.

## Development

Build custom package:

```sh
nix build .#PACKAGE
```

## Adding a host

1. Add the host configuration to `hosts/{HOST_NAME}/default.nix`. Modify `home.nix` and `host.nix` as needed.
2. Generate the host keys, add the public key to your secrets, and re-encrypt the secrets.
3. Add the new host configuration to `hosts/default.nix`.
4. Deploy the configuration to your host.
   - If you're adding a new host with a standalone Home Manager setup, using `nix develop` might be helpful.

### Raspberry Pi: Build and Flash an SD Card Image

We use [raspberry-pi-nix](https://github.com/nix-community/raspberry-pi-nix) for
Raspberry Pi setup. Make sure to check the documentation first.

Building an image and flashing it to an SD card is an effective way to set up your
Raspberry Pi:

```sh
nix build '.#nixosConfigurations.rpi-example.config.system.build.sdImage'
zstdcat result/sd-image/nixos-sd-image-23.11.20230703.ea4c80b-aarch64-linux.img.zst \
    | sudo dd of=/dev/mmcblk0 bs=100M
```

This method creates and deploys a ready-to-use NixOS image to your SD card.

## Known issues

### Darwin apps in dock

To remove the uninstalled APPs icon from Launchpad:

1.  `sudo nix store gc --debug && sudo nix-collect-garbage --delete-old`
2.  click on the uninstalled APP's icon in Launchpad, it will show a question mark
3.  if the app starts normally:
    1.  right click on the running app's icon in Dock, select "Options" -> "Show in Finder" and delete it
4.  hold down the Option key, a `x` button will appear on the icon, click it to remove the icon

### Home Manager + Agenix

Each time when you add/edit/delete home secrets, you will have to run the following script manually:

```sh
systemctl --user start agenix.service
```

This is [a bug with agenix](https://github.com/ryantm/agenix/issues/50#issuecomment-1712597733)
