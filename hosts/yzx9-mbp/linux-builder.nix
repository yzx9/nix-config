# Darwin Linux Builder
# try remote build: https://nixcademy.com/posts/macos-linux-builder/
{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.nixos-rebuild ];

  nix.linux-builder = {
    enable = true;

    # Wipe the builder's filesystem on every restart
    # `du -h /var/lib/darwin-builder/nixos.qcow2`
    ephemeral = true;

    # The defaults are 1 CPU core, 3GB RAM, and 20GB disk
    # Don't apply any config before the first build
    config = {
      virtualisation = {
        darwin-builder = {
          diskSize = 40 * 1024; # 40 GB
          memorySize = 32 * 1024; # 32 GB
        };

        cores = 8;
      };
    };
  };
}
