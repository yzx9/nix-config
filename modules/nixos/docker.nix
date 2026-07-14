{ config, lib, ... }:

let
  cfg = config.my.docker;

  proxySettings = lib.mkIf config.my.proxy.selfHost.enable {
    "http-proxy" = "127.0.0.1:${toString config.my.proxy.selfHost.httpPort}";
    "no-proxy" = "127.0.0.0/8";
  };
in
lib.mkIf cfg.enable {
  virtualisation.docker = {
    enable = true;

    daemon.settings = proxySettings;

    rootless = {
      enable = cfg.rootless;
      setSocketVariable = true;
      daemon.settings = proxySettings;
    };
  };

  # WARN: Beware that the docker group membership is effectively equivalent to being root!
  users.extraGroups.docker.members = lib.mkIf (!cfg.rootless) [ config.my.user.name ];

  # use `docker run` with `--device nvidia.com/gpu=all`` and not `--gpus all`
  hardware.nvidia-container-toolkit.enable = config.my.nvidia.enable;
}
