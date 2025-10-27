# nix-config

Personal nix-config.

Current state: nixos, nix-darwin and standalone home-manager.

## Development

Build custom package:

```sh
nix build .#PACKAGE
```

## Adding a host

General way:

1. Add the host configuration to `hosts/$(hostname)/default.nix`, modify `home.nix` and `host.nix` as needed.
2. Generate the host keys, add the public key to `secrets/secrets.nix`, and re-encrypt the secrets using `agenix -r`.
3. Add the new host configuration to `hosts/default.nix`.
4. Deploy the configuration to your host.
   - If you're adding a new host with a standalone Home Manager setup, using `nix develop` might be helpful.
   - Check the `deploy` command in `justfile`, if applicable

### Raspberry Pi: Build and Flash an SD Card Image

We use [`nixos-raspberrypi`](https://github.com/nvmd/nixos-raspberrypi) for Raspberry Pi setup. Make sure to check the
documentation first.

Building an image and flashing it to an SD card is an effective way to set up your Raspberry Pi. However, creating an
SD card image using `nixos-raspberrypi` can take some effort. We recommend starting with an official example:

```sh
# Clone the repo and update the config as needed
nix build 'github:nvmd/nixos-raspberrypi#nixosConfigurations.installerImages.rpi5'
```

This method builds a ready-to-use NixOS image. You can flash it directly to your SD card:

```sh
zstdcat result/sd-image/nixos-sd-image-23.11.20230703.ea4c80b-aarch64-linux.img.zst \
    | sudo dd of=/dev/mmcblk0 bs=100M
```

After booting, you’ll have a running NixOS system on your Raspberry Pi. From there, you can deploy your own
configuration.

## Known issues

### Darwin

#### Daemons not running

Check the daemon status and try to bootstrap/start them:

```sh
ls /Library/LaunchDaemons
sudo launchctl print system/org.nixos.bar
sudo launchctl bootstarp system /Library/LaunchDaemons/org.nixos.bar
sudo launchctl kickstart -k system/org.nixos.bar
```

If this resolves the issue, please verify permissions in `Settings` -> `General` -> `Login Items & Extensions`.
Make sure all relevant entries are enabled (including `sh`, most Nix-Darwin services run using `sh -c bar`).

And you can check the log:

```sh
sudo log show --last boot --predicate "process == 'launchd' AND composedMessage CONTAINS 'org.nixos.xray'"
```

#### Uninstalled apps in Launchpad

To remove the uninstalled APPs icon from Launchpad:

1.  Run command: `sudo nix store gc --debug && sudo nix-collect-garbage --delete-old`
2.  Click on the uninstalled APP's icon in Launchpad, it will show a question mark
3.  If the app starts normally, right click on the running app's icon in Dock, select "Options" -> "Show in Finder" and
    delete it
4.  Hold down the Option key, a `x` button will appear on the icon, click it to remove the icon

#### Remove old version entries from Finder

```sh
# re-register regular apps
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -kill -r -domain local -domain system -domain user

# re-register nixpkgs
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -R -v "/Applications/Nix Apps"

# restart Finder to see effect
killall Finder
```

### Agenix

#### Service restart

Agenix secrets are runtime-only resources, meaning that the NixOS hot-reload system cannot detect changes to them.
Therefore, it is necessary to manually restart any related services.

#### Debugging activation on darwin

First, check weather the decrypted target directory exists. If it does not, verify the daemon status (see section above).

Then, enable logging by adding the following configuration.

```nix
launchd.daemons.activate-agenix.serviceConfig = {
  StandardOutPath = "/var/log/activate-agenix.out";
  StandardErrorPath = "/var/log/activate-agenix.err";
};
```

#### Home Manager

Each time when you add/edit/delete home secrets, you will have to run the following script manually:

```sh
systemctl --user start agenix.service
```

This is [a bug with agenix](https://github.com/ryantm/agenix/issues/50#issuecomment-1712597733).

### Proxy

#### Setup proxy with systemd override (especially useful for non-nixos)

```sh
# https://github.com/NixOS/nixpkgs/issues/27535#issuecomment-1178444327
# equals: sudo systemctl edit --runtime nix-daemon
sudo mkdir /run/systemd/system/nix-daemon.service.d/
cat << EOF >/run/systemd/system/nix-daemon.service.d/override.conf
[Service]
Environment="http_proxy=socks5h://localhost:7891"
Environment="https_proxy=socks5h://localhost:7891"
Environment="all_proxy=socks5h://localhost:7891"
EOF
sudo systemctl daemon-reload
sudo systemctl restart nix-daemon
```

#### Proxy may be a problem when your proxy server stops to work...

```sh
sudo mount -o remount,rw /nix/store
# Look for the file and remove the lines:
sudo systemstd cat nix-daemon
sudo mount -o remount,ro /nix/store
sudo systemctl stop nix-daemon.socket nix-daemon
sudo systemctl start nix-daemon
```

### NVIDIA Driver

After upgrading the NVIDIA driver, you may encounter:

```sh
nvidia-smi
Failed to initialize NVML: Driver/library version mismatch
```

To fix it, you need to reload the driver. The easiest way is **rebooting**.
If you can't reboot, follow these steps:

1. Check which modules are loaded: `lsmod | grep nvidia` and find processes using NVIDIA: `lsof | grep nvidia`
2. Stop services if needed (e.g., stop GNOME with `sudo systemctl isolate multi-user.target`)
3. Unload modules: `sudo modprobe -r nvidia_uvm nvidia_drm nvidia_modeset nvidia`. If `modprobe -r` fails, check what
   is still using the modules and kill the processes manually.
4. Reload module: `sudo modprobe nvidia`
5. Test again: `nvidia-smi`. If problems persist, a full system reboot is recommended.
