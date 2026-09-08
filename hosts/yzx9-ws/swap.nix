{
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50; # 32GB zram logical capacity
    priority = 100; # Prefer zram over disk swap
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024; # 16 GiB
      priority = 10; # Only fall back to disk after zram
    }
  ];

  boot.kernel.sysctl."vm.swappiness" = 100;
}
