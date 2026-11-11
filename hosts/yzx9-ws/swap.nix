{
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50; # 64GB zram logical capacity
    priority = 100; # Prefer zram over disk swap
  };

  # Optional disk swap on the NVMe Btrfs filesystem; leave disabled for now.
  # Before enabling, create @swap at the filesystem top level (alongside @root),
  # not inside @root. Keep @swap out of snapshots.
  # fileSystems."/swap" = {
  #   device = "/dev/disk/by-uuid/d777e2c6-153d-4e5e-85a9-94f9ea844ab5";
  #   fsType = "btrfs";
  #   options = [
  #     "subvol=@swap"
  #     "noatime"
  #   ];
  # };
  #
  # NixOS creates a Btrfs-compatible swapfile with CoW and compression disabled.
  # swapDevices = [
  #   {
  #     device = "/swap/swapfile";
  #     size = 16 * 1024; # MiB: 16 GiB
  #     priority = 10; # Only fall back to disk after zram
  #   }
  # ];

  boot.kernel.sysctl."vm.swappiness" = 100;
}
