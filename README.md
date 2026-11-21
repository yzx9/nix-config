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

Each Raspberry Pi host has a ready-to-flash SD card image built with
[`nixos-raspberrypi`](https://github.com/nvmd/nixos-raspberrypi). Choose one of the following:

- **GitHub Actions:** Open **Actions → Build SD card image → Run workflow** and select the host. Download and extract
  the artifact within one day. From the extracted directory, verify `sd.img.zst` with `sha256sum -c SHA256SUMS`
  (macOS: `shasum -a 256 -c SHA256SUMS`).
- **Local build:** Build the `images.<host>` flake output, for example with `nix build .#images.yzx9-rpi5`.
  Use `result/sd-image/*.img.zst` in place of `sd.img.zst` below.

Flashing erases the card. Identify the device with `lsblk` (Linux) or `diskutil list` (macOS), then replace `sdX` or
`diskN` below with the correct device. Write to the **whole card**, not a partition.

```sh
# Linux: unmount each mounted partition on the card before writing.
# For example: sudo umount /dev/sdX1
zstdcat sd.img.zst | sudo dd of=/dev/sdX bs=100M status=progress conv=fsync

# macOS:
diskutil unmountDisk /dev/diskN
zstdcat sd.img.zst | sudo dd of=/dev/rdiskN bs=100m
```

The image contains the full `aarch64-linux` system and uses the `FIRMWARE` and `NIXOS_SD` partition labels expected by
`hardware-configuration.nix`. The root partition expands on first boot. The image does not include agenix identity keys;
provision the matching private keys on the Pi before starting services that need those secrets.

## Known issues

### Substituter not activated

Check your current nix config:

```sh
nix config show
```

Also check weather there is a user-wide config at `~/.config/nix`

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
sudo systemctl cat nix-daemon
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

### How to override ...?

#### Rust

```nix
goose-cli = prev.goose-cli.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.18.0";
  src = prev.fetchFromGitHub {
    owner = "block";
    repo = "goose";
    tag = "v${finalAttrs.version}";
    hash = "";
  };
  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) src;
    hash = "";
  };
});
```

#### Vim plugins

```nix
final: prev: {
  vimPlugins = prev.vimPlugins // {
    fzf-lua = prev.neovimUtils.buildNeovimPlugin {
      luaAttr = prev.luaPackages.fzf-lua.overrideAttrs (oldAttrs: {
        version = "0.0.2311-1";

        knownRockspec =
          (prev.fetchurl {
            url = "mirror://luarocks/fzf-lua-0.0.2311-1.rockspec";
            sha256 = "0ldxn3v2bkjydnqcq5zz0rxxlv953azi6zvm8hl9vdsil1gg9vcz";
          }).outPath;

        src = prev.fetchzip {
          url = "https://github.com/ibhagwan/fzf-lua/archive/3170d98240266a68c2611fc63260c3ab431575aa.zip";
          sha256 = "0zlrzvwc29arf8y6x6niyglqgvj403mryffnwq18nmd6gabrjjx1";
        };
      });
    };
  };
}
```
