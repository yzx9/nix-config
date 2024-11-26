{ inputs, lib, ... }:

let
  inherit (inputs) raspberry-pi-nix;
in
{
  # nix build .#nixosConfigurations.pi5.config.system.build.sdImage
  # zstdcat result/sd-image/nixos-sd-image-23.11.20230703.ea4c80b-aarch64-linux.img.zst | sudo dd of=/dev/mmcblk0 bs=100M
  imports = [
    raspberry-pi-nix.nixosModules.raspberry-pi

    raspberry-pi-nix.nixosModules.sd-image
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

  raspberry-pi-nix.board = "bcm2712";

  hardware.raspberry-pi.config = {
    all = {
      base-dt-params = {
        BOOT_UART = {
          value = 1;
          enable = true;
        };
        uart_2ndstage = {
          value = 1;
          enable = true;
        };
      };
      dt-overlays = {
        disable-bt = {
          enable = true;
          params = { };
        };
      };
    };
  };
}
