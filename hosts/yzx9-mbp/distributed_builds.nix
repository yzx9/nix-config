{
  # When first time building, you need to run
  # > sudo launchctl kickstart -k system/org.nixos.nix-daemon
  age.secrets = {
    id-auth = {
      file = ../../secrets/id-auth_root.age;
      path = "/var/root/.ssh/id_auth";
      owner = "root";
      group = "wheel";
      mode = "400";
    };

    ssh-config = {
      file = ../../secrets/ssh-config.age;
      path = "/var/root/.ssh/config";
      owner = "root";
      group = "wheel";
      mode = "400";
    };
  };

  # required, otherwise remote buildMachines above aren't used
  nix.distributedBuilds = true;

  # You can see the resulting builder-strings of this NixOS-configuration with "cat /etc/nix/machines".
  # These builder-strings are used by the Nix terminal tool, e.g.
  # when calling "nix build ...".
  nix.buildMachines = [
    {
      # Will be used to call "ssh builder" to connect to the builder machine.
      # The details of the connection (user, port, url etc.)
      # are taken from your "~/.ssh/config" file.
      hostName = "yzx9-ws";
      # sshUser = "";
      # sshKey = "/etc/nix/builder_ed25519";
      # publicHostKey = "";

      # CPU architecture of the builder, and the operating system it runs.
      # See https://github.com/NixOS/nixpkgs/blob/nixos-unstable/lib/systems/flake-systems.nix
      # If your builder supports multiple architectures
      # (e.g. search for "binfmt" for emulation),
      # you can list them all, e.g. replace with
      systems = [
        "x86_64-linux"
        "aarch64-linux" # QEMU emulation
      ];
      # system = "x86_64-linux";

      # Nix custom ssh-variant that avoids lots of "trusted-users" settings pain
      protocol = "ssh-ng";

      # default is 1 but may keep the builder idle in between builds
      maxJobs = 4;

      # how fast is the builder compared to your local machine
      speedFactor = 2;

      supportedFeatures = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
      mandatoryFeatures = [ ];
    }

    # disabled as linux-builder got enabled
    # {
    #   hostName = "yzx9-rpi5";
    #   systems = [ "aarch64-linux" ];
    #   protocol = "ssh-ng";
    #   supportedFeatures = [
    #     "nixos-test"
    #     "benchmark"
    #     "big-parallel"
    #     "kvm"
    #   ];
    # }
  ];

  # # optional, useful when the builder has a faster internet connection than yours
  # nix.settings = {
  #   builders-use-substitutes = true;
  # };

  # Darwin Linux Builder
  # try remote build: https://nixcademy.com/posts/macos-linux-builder/
  nix.linux-builder = {
    enable = true;

    # Wipe the builder's filesystem on every restart
    # `du -h /var/lib/linux-builder/nixos.qcow2`
    ephemeral = true;

    maxJobs = 4; # set to half of the number of CPU cores

    # The defaults are 1 CPU core, 3GB RAM, and 20GB disk
    # Don't apply any config before the first build
    config.virtualisation = {
      darwin-builder = {
        diskSize = 80 * 1024; # 80 GB
        memorySize = 32 * 1024; # 32 GB
      };

      cores = 8;
    };
  };
}
